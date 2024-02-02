# frozen_string_literal: false

require 'spec_helper'
require 'stripe/credit_card_remover'

describe Stripe::CreditCardRemover do
  let(:credit_card) { create(:credit_card, gateway_payment_profile_id: pm_card.id, user:) }

  let!(:user) { create(:user, email: "apple.customer@example.com") }
  let!(:enterprise) { create(:enterprise) }

  describe "#remove", :vcr, :stripe_version do
    let(:stripe_account_id) { ENV.fetch('STRIPE_ACCOUNT', nil) }

    let(:stripe_account) {
      create(:stripe_account, enterprise:, stripe_user_id: stripe_account_id)
    }

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
      Stripe::Account.create(
        type: 'standard',
        country: 'AU',
        email: 'apple.producer@example.com'
      )
    end

    let(:cloner) { Stripe::CreditCardCloner.new(credit_card, connected_account.id) }

    context 'Stripe customer exists' do
      let(:payment_method_id) { pm_card.id }
      let(:customer_id) { customer.id }

      let(:customer) do
        Stripe::Customer.create({
                                  name: 'Apple Customer',
                                  email: 'applecustomer@example.com',
                                })
      end

      before do
        Stripe::PaymentMethod.attach(
          payment_method_id,
          { customer: customer_id },
        )

        credit_card.update_attribute :gateway_customer_profile_id, customer_id
      end

      context 'and is not deleted' do
        it 'deletes the credit card clone and the customer' do
          response = Stripe::CreditCardRemover.new(credit_card).call

          expect(response.deleted).to eq(true)
        end
      end

      context 'and is deleted' do
        it 'deletes the credit card clone' do
          customer = double('customer', deleted?: true)
          allow(Stripe::Customer).to receive(:retrieve).and_return(customer)

          expect_any_instance_of(Stripe::CreditCardCloneDestroyer).to receive(:destroy_clones).with(
            credit_card
          )
          expect(customer).not_to receive(:delete)
          Stripe::CreditCardRemover.new(credit_card).call
        end
      end
    end

    context 'Stripe customer does not exist' do
      let(:non_existing_customer_id) { 'non_existing_customer_id' }

      before do
        credit_card.update_attribute :gateway_customer_profile_id, non_existing_customer_id
      end

      it 'raises an error' do
        expect {
          Stripe::CreditCardRemover.new(credit_card).call
        }.to raise_error Stripe::InvalidRequestError
      end
    end
  end
end
