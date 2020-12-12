# frozen_string_literal: false

require 'spec_helper'
require 'stripe/credit_card_remover'

describe Stripe::CreditCardRemover do
  let(:credit_card) { double('credit_card', gateway_customer_profile_id: 1) }

  context 'Stripe customer exists' do
    context 'and is not deleted' do
      it 'deletes the credit card clone and the customer' do
        customer = double('customer', deleted?: false)
        allow(Stripe::Customer).to receive(:retrieve).and_return(customer)

        expect_any_instance_of(Stripe::CreditCardCloneDestroyer).to receive(:destroy_clones).with(
          credit_card
        )
        expect(customer).to receive(:delete)
        Stripe::CreditCardRemover.new(credit_card).call
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
    it 'deletes the credit card clone' do
      allow(Stripe::Customer).to receive(:retrieve).and_return(nil)

      expect_any_instance_of(Stripe::CreditCardCloneDestroyer).to receive(:destroy_clones).with(
        credit_card
      )
      Stripe::CreditCardRemover.new(credit_card).call
    end
  end
end
