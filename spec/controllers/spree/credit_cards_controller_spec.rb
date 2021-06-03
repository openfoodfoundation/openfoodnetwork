# frozen_string_literal: true

require 'spec_helper'

describe Spree::CreditCardsController, type: :controller do
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

    context "when the request to store the customer/card with Stripe is successful" do
      let(:response_mock) { { status: 200, body: JSON.generate(id: "cus_AZNMJ", default_source: "card_1AEEb") } }

      it "saves the card locally" do
        spree_post :new_from_token, params

        expect{ spree_post :new_from_token, params }.to change(Spree::CreditCard, :count).by(1)

        card = Spree::CreditCard.last
        expect(card.gateway_payment_profile_id).to eq "card_1AEEb"
        expect(card.gateway_customer_profile_id).to eq "cus_AZNMJ"
        expect(card.user_id).to eq user.id
        expect(card.last_digits).to eq "4242"
      end

      context "when saving the card locally fails" do
        before do
          allow(controller).to receive(:stored_card_attributes) { {} }
        end

        it "renders a flash error" do
          expect{ spree_post :new_from_token, params }.to_not change(Spree::CreditCard, :count)

          json_response = JSON.parse(response.body)
          flash_message = I18n.t(:spree_gateway_error_flash_for_checkout, error: I18n.t(:card_could_not_be_saved))
          expect(json_response["flash"]["error"]).to eq flash_message
        end
      end
    end

    context "when the request to store the customer/card with Stripe fails" do
      let(:response_mock) { { status: 402, body: JSON.generate(error: { message: "Bup-bow..." }) } }
      it "doesn't save the card locally, and renders a flash error" do
        expect{ spree_post :new_from_token, params }.to_not change(Spree::CreditCard, :count)

        json_response = JSON.parse(response.body)
        flash_message = I18n.t(:spree_gateway_error_flash_for_checkout, error: "Bup-bow...")
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
        expect(json_response['flash']['error']).to eq I18n.t(:card_could_not_be_updated)
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
            expect(json_response['flash']['error']).to eq I18n.t(:card_could_not_be_updated)
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
        expect(flash[:error]).to eq I18n.t(:card_could_not_be_removed)
        expect(response).to redirect_to spree.account_path(anchor: 'cards')
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
            expect(flash[:error]).to eq I18n.t(:card_could_not_be_removed)
            expect(response).to redirect_to spree.account_path(anchor: 'cards')
          end
        end

        context "where the request to destroy the Stripe customer succeeds" do
          before do
            stub_request(:delete, "https://api.stripe.com/v1/customers/cus_AZNMJ").
              to_return(status: 200, body: JSON.generate(deleted: true, id: "cus_AZNMJ"))
          end

          it "deletes the card and redirects to account_path" do
            expect{ spree_delete :destroy, params }.to change(Spree::CreditCard, :count).by(-1)
            expect(flash[:success]).to eq I18n.t(:card_has_been_removed, number: "x-#{card.last_digits}")
            expect(response).to redirect_to spree.account_path(anchor: 'cards')
          end

          context "the card is the default card and there are existing authorizations for the user" do
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
          end
        end
      end
    end
  end
end
