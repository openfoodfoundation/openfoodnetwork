# frozen_string_literal: true

require 'stripe/credit_card_clone_destroyer'

module Stripe
  class CreditCardRemover
    def initialize(credit_card)
      @credit_card = credit_card
    end

    def call
      Stripe::CreditCardCloneDestroyer.new.destroy_clones(@credit_card)

      stripe_customer = Stripe::Customer.retrieve(@credit_card.gateway_customer_profile_id, {})
      return unless stripe_customer

      stripe_customer.delete unless stripe_customer.deleted?
    end
  end
end
