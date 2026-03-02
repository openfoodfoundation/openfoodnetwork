# frozen_string_literal: true

module Stripe
  RSpec.describe ProfileStorer do
    include StripeStubs

    describe "create_customer_from_token", :vcr, :stripe_version do
      let(:pm_card) do
        Stripe::PaymentMethod.create({
                                       type: 'card',
                                       card: {
                                         number: '4242424242424242',
                                         exp_month: 12,
                                         exp_year: Time.zone.now.year.next,
                                         cvc: '314',
                                       },
                                     })
      end

      let(:credit_card) { create(:credit_card, gateway_payment_profile_id: pm_card.id) }

      let(:stripe_payment_method) {
        create(:stripe_sca_payment_method, distributor_ids: [create(:distributor_enterprise).id],
                                           preferred_enterprise_id: create(:enterprise).id)
      }

      let(:payment) {
        create(
          :payment,
          payment_method: stripe_payment_method,
          source: credit_card,
        )
      }

      let(:profile_storer) { Stripe::ProfileStorer.new(payment, stripe_payment_method.provider) }

      context "when called from Stripe SCA" do
        it "fetches the customer id and the card id from the correct response fields" do
          profile_storer.create_customer_from_token

          expect(payment.source.gateway_customer_profile_id).to match(/cus_/)
          expect(payment.source.gateway_payment_profile_id).to eq pm_card.id
        end
      end
      context "when request fails" do
        let(:message) {
          'The payment method you provided has already been attached to a customer.'
        }

        let(:customer) do
          Stripe::Customer.create({
                                    name: 'Apple Customer',
                                    email: 'applecustomer@example.com',
                                  })
        end

        before do
          Stripe::PaymentMethod.attach(
            pm_card.id,
            { customer: customer.id },
          )
        end
        it "raises an error" do
          expect { profile_storer.create_customer_from_token }.to raise_error(
            Spree::Core::GatewayError, message
          )
        end
      end
    end
  end
end
