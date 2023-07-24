# frozen_string_literal: true

require 'spec_helper'

describe Spree::CreditCardsController, type: :controller do
  describe "using VCR", :vcr do
    let(:user) { create(:user) }
    let(:secret) { ENV['STRIPE_SECRET_TEST_API_KEY'] }

    before do
      Stripe.api_key = secret
      allow(controller).to receive(:spree_current_user) { user }
    end

    describe "#new_from_token" do
      let!(:token) do
        Stripe::Token.create({
                               card: {
                                 number: '4242424242424242',
                                 exp_month: 9,
                                 exp_year: 2024,
                                 cvc: '314',
                               },
                             })
      end
      context "when the request to store the customer/card with Stripe is successful" do
        let(:params) do
          {
            format: :json,
            exp_month: 9,
            exp_year: 2024,
            last4: 4242,
            token: token['id'],
            cc_type: "visa"
          }
        end

        before do
          # there should be no cards stored locally
          expect(Spree::CreditCard.count).to eq(0)
        end

        it "saves the card locally" do
          spree_post :new_from_token, params

          # checks whether a card was created
          expect(Spree::CreditCard.count).to eq(1)
          card = Spree::CreditCard.last

          # retrieves the created card from Stripe
          stripe_card = Stripe::Customer.list_sources(
            card.gateway_customer_profile_id,
            { object: 'card', limit: 1 },
          )

          payment_profile = stripe_card['data'][0]['id']
          customer_profile = stripe_card['data'][0]['customer']

          expect(card.gateway_payment_profile_id).to eq payment_profile
          expect(card.gateway_customer_profile_id).to eq customer_profile
          expect(card.user_id).to eq user.id
          expect(card.last_digits).to eq "4242"
        end
      end
    end
  end

  describe "not using VCR" do
    let(:user) { create(:user) }
    let(:token) { "tok_234bd2c22" }

    before do
      Stripe.api_key = "sk_test_12345"
      allow(controller).to receive(:spree_current_user) { user }
    end
    describe "#new_from_token" do
      let(:params) do
        {
          format: :json,
          exp_month: 12,
          exp_year: Time.now.year.next,
          last4: 4242,
          token: token,
          cc_type: "visa"
        }
      end

      before do
        stub_request(:post, "https://api.stripe.com/v1/customers")
          .with(body: { email: user.email, source: token })
          .to_return(response_mock)
      end

      context "when the request to store the customer/card with Stripe fails" do
        let(:response_mock) {
          { status: 402, body: JSON.generate(error: { message: "Bup-bow..." }) }
        }
        it "doesn't save the card locally, and renders a flash error" do
          expect{ spree_post :new_from_token, params }.to_not change(Spree::CreditCard, :count)

          json_response = JSON.parse(response.body)
          flash_message = "There was a problem with your payment information: %s" % 'Bup-bow...'
          expect(json_response["flash"]["error"]).to eq flash_message
        end
      end
    end

    describe "#update card to be the default card" do
      let(:params) { { format: :json, credit_card: { is_default: true } } }
      context "when the specified credit card is not found" do
        before { params[:id] = 123 }

        it "renders a flash error" do
          spree_put :update, params
          json_response = JSON.parse(response.body)
          expect(json_response['flash']['error']).to eq 'Card could not be updated'
        end
      end

      context "when the specified credit card is found" do
        let!(:card) { create(:credit_card, gateway_customer_profile_id: 'cus_AZNMJ') }
        before { params[:id] = card.id }

        context "but the card is not owned by the user" do
          it "redirects to unauthorized" do
            spree_put :update, params
            expect(response).to redirect_to unauthorized_path
          end
        end

        context "and the card is owned by the user" do
          before { card.update_attribute(:user_id, user.id) }

          context "when the update completes successfully" do
            it "renders a serialized copy of the updated card" do
              expect{ spree_put :update, params }.to change { card.reload.is_default }.to(true)
              json_response = JSON.parse(response.body)
              expect(json_response['id']).to eq card.id
              expect(json_response['is_default']).to eq true
            end
          end

          context "when the update fails" do
            before { params[:credit_card][:month] = 'some illegal month' }
            it "renders an error" do
              spree_put :update, params
              json_response = JSON.parse(response.body)
              expect(json_response['flash']['error']).to eq 'Card could not be updated'
            end
          end

          context "and there are existing authorizations for the user" do
            let!(:customer1) { create(:customer, allow_charges: true) }
            let!(:customer2) { create(:customer, allow_charges: true) }

            it "removes the authorizations" do
              customer1.user = card.user
              customer2.user = card.user
              customer1.save
              customer2.save
              expect(customer1.reload.allow_charges).to be true
              expect(customer2.reload.allow_charges).to be true
              spree_put :update, params
              expect(customer1.reload.allow_charges).to be false
              expect(customer2.reload.allow_charges).to be false
            end
          end
        end
      end
    end

    describe "#destroy" do
      context "when the specified credit card is not found" do
        let(:params) { { id: 123 } }

        it "redirects to /account with a flash error, does not request deletion with Stripe" do
          expect(controller).to_not receive(:destroy_at_stripe)
          spree_delete :destroy, params
          expect(flash[:error]).to eq 'Sorry, the card could not be removed'
          expect(response.status).to eq 200
        end
      end

      context "when the specified credit card is found" do
        let!(:card) { create(:credit_card, gateway_customer_profile_id: 'cus_AZNMJ') }
        let(:params) { { id: card.id } }

        context "but the card is not owned by the user" do
          it "redirects to unauthorized" do
            spree_delete :destroy, params
            expect(response).to redirect_to unauthorized_path
          end
        end

        context "and the card is owned by the user" do
          before do
            card.update_attribute(:user_id, user.id)

            stub_request(:get, "https://api.stripe.com/v1/customers/cus_AZNMJ").
              to_return(status: 200, body: JSON.generate(id: "cus_AZNMJ"))
          end

          context "where the request to destroy the Stripe customer fails" do
            before do
              stub_request(:delete, "https://api.stripe.com/v1/customers/cus_AZNMJ").
                to_return(status: 402, body: JSON.generate(error: { message: 'Bup-bow!' }))
            end

            it "doesn't delete the card" do
              expect{ spree_delete :destroy, params }.to_not change(Spree::CreditCard, :count)
              expect(flash[:error]).to eq 'Sorry, the card could not be removed'
              expect(response.status).to eq 422
            end
          end

          context "where the request to destroy the Stripe customer succeeds" do
            before do
              stub_request(:delete, "https://api.stripe.com/v1/customers/cus_AZNMJ").
                to_return(status: 200, body: JSON.generate(deleted: true, id: "cus_AZNMJ"))
            end

            it "deletes the card and redirects to account_path" do
              expect{ spree_delete :destroy, params }.to change(Spree::CreditCard, :count).by(-1)
              expect(flash[:success])
                .to eq "Your card has been removed (number: %s)" % "x-#{card.last_digits}"
              expect(response.status).to eq 200
            end

            context "card is the default card and there are existing authorizations for the user" do
              before do
                card.update_attribute(:is_default, true)
              end
              let!(:customer1) { create(:customer, allow_charges: true) }
              let!(:customer2) { create(:customer, allow_charges: true) }

              it "removes the authorizations" do
                customer1.user = card.user
                customer2.user = card.user
                customer1.save
                customer2.save
                expect(customer1.reload.allow_charges).to be true
                expect(customer2.reload.allow_charges).to be true
                spree_delete :destroy, params
                expect(customer1.reload.allow_charges).to be false
                expect(customer2.reload.allow_charges).to be false
              end

              context "when has any other saved cards" do
                let!(:second_card) {
                  create(:stored_credit_card, user_id: user.id,
                                              gateway_customer_profile_id: 'cus_AZNMJ')
                }

                it "should assign the second one as the default one" do
                  spree_delete :destroy, params
                  expect(Spree::CreditCard.find_by(id: second_card.id).is_default).to eq true
                end
              end
            end
          end
        end
      end
    end
  end
end
