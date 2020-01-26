# frozen_string_literal: true

# Here we clone
# - a card (card_*) stored in a customer in a platform account
# into
# - a payment method (pm_*) in a new customer in a connected account
#
# This process is used in the migration between using the Stripe Charges API (stripe_connect)
#   and the Stripe Payment Intents API (stripe_sca)
#
# This process can be deleted once all hubs are running on the new stripe_sca method and all cards in the system have been migrated to the new payment_methods
#   Basically, when all DBs have no card_* values in credit_card.gateway_payment_profile_id
module Stripe
  class CreditCardCloner
    def clone!(credit_card, stripe_account_id)
      return unless credit_card.gateway_payment_profile_id.starts_with?('card_')

      new_payment_method = clone_payment_method(credit_card, stripe_account_id)
      new_customer = Stripe::Customer.create({ email: credit_card.user.email },
                                             stripe_account: stripe_account_id)
      attach_payment_method_to_customer(new_payment_method.id, new_customer.id, stripe_account_id)

      credit_card.update_attributes gateway_customer_profile_id: new_customer.id,
                                    gateway_payment_profile_id: new_payment_method.id
      credit_card
    end

    private

    def clone_payment_method(credit_card, stripe_account_id)
      card_id = credit_card.gateway_payment_profile_id
      customer_id = credit_card.gateway_customer_profile_id

      Stripe::PaymentMethod.create({ customer: customer_id, payment_method: card_id },
                                   stripe_account: stripe_account_id)
    end

    def attach_payment_method_to_customer(payment_method_id, customer_id, stripe_account_id)
      Stripe::PaymentMethod.attach(payment_method_id,
                                   { customer: customer_id },
                                   stripe_account: stripe_account_id)
    end
  end
end
