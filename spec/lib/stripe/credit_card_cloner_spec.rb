# frozen_string_literal: true

require 'stripe/credit_card_cloner'

module Stripe
  RSpec.describe CreditCardCloner do
    let!(:user) { create(:user, email: "apple.customer@example.com") }
    let!(:enterprise) { create(:enterprise) }

    describe "#find_or_clone", :vcr, :stripe_version do
      let(:customer) do
        Stripe::Customer.create({
                                  name: 'Apple Customer',
                                  email: 'apple.customer@example.com',
                                })
      end

      let(:customer_id) { customer.id }

      let(:credit_card) { create(:credit_card, gateway_payment_profile_id: pm_card.id, user:) }

      let(:pm_card) {
        Stripe::PaymentMethod.create(
          {
            type: 'card',
            card: {
              number: '4242424242424242',
              exp_month: 8,
              exp_year: Time.zone.now.year.next,
              cvc: '314',
            },
          },
        )
      }

      let(:connected_account) do
        Stripe::Account.create({
                                 type: 'standard',
                                 country: 'AU',
                                 email: 'apple.producer@example.com'
                               })
      end

      let(:cloner) { Stripe::CreditCardCloner.new(credit_card, connected_account.id) }

      after do
        Stripe::Account.delete(connected_account.id)
      end

      context "when called with a card without a customer (one time usage card)" do
        let(:payment_method_id) { pm_card.id }

        it "clones the payment method only" do
          customer_id, new_payment_method_id = cloner.find_or_clone

          expect(payment_method_id).to match(/pm_/)
          expect(new_payment_method_id).to match(/pm_/)
          expect(payment_method_id).not_to eq new_payment_method_id
          expect(customer_id).to eq nil
        end
      end

      context "when called with a valid customer and payment_method" do
        let(:payment_method_id) { pm_card.id }

        before do
          Stripe::PaymentMethod.attach(
            payment_method_id,
            { customer: customer_id },
          )

          credit_card.update_attribute :gateway_customer_profile_id, customer_id
        end

        it "clones both the payment method and the customer" do
          new_customer_id, new_payment_method_id = cloner.find_or_clone

          expect(payment_method_id).to match(/pm_/)
          expect(new_payment_method_id).to match(/pm_/)
          expect(payment_method_id).not_to eq new_payment_method_id
          expect(new_customer_id).to match(/cus_/)
          expect(customer_id).not_to eq new_customer_id
        end
      end
    end
  end
end
