# frozen_string_literal: true

module Stripe
  class CreditCardCloneFinder
    def initialize(card, stripe_account)
      @card = card
      @stripe_account = stripe_account
    end

    def find_cloned_card
      return nil unless fingerprint = fingerprint_for_card(@card)
      return nil unless email = @card.user&.email

      customers = Stripe::Customer.list({ email: email, limit: 100 },
                                        stripe_account: @stripe_account)

      customers.auto_paging_each do |customer|
        options = { customer: customer.id, type: 'card', limit: 100 }
        payment_methods = Stripe::PaymentMethod.list(options, stripe_account: @stripe_account)
        payment_methods.auto_paging_each do |payment_method|
          return [customer.id, payment_method.id] if clone?(payment_method, fingerprint)
        end
      end
      nil
    end

    private

    def clone?(payment_method, fingerprint)
      payment_method.card.fingerprint == fingerprint && payment_method.metadata["ofn-clone"]
    end

    def fingerprint_for_card(card)
      Stripe::PaymentMethod.retrieve(card.gateway_payment_profile_id).card.fingerprint
    end
  end
end
