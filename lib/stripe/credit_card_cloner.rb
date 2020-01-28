# frozen_string_literal: true

# Here we clone
#   - a card (card_*) or payment_method (pm_*) stored (in a customer) in a platform account
# into
#   - a payment method (pm_*) (in a new customer) in a connected account
#
# This is required when using the Stripe Payment Intents API:
#   - the customer and payment methods are stored in the platform account
#       so that they can be re-used across multiple sellers
#   - when a card needs to be charged, we need to create it in the seller's stripe account
#
# We are doing this process every time the card is charged:
#   - this means that, if the customer uses the same card on the same seller multiple times,
#       the card will be created multiple times on the seller's account
#   - to avoid this, we would have to store the IDs of every card on each seller's stripe account
#       in our database (this way we only have to store the platform account ID)
module Stripe
  class CreditCardCloner
    def clone(credit_card, connected_account_id)
      new_payment_method = clone_payment_method(credit_card, connected_account_id)

      # If no customer is given, it will clone the payment method only
      return nil, new_payment_method.id if credit_card.gateway_customer_profile_id.blank?

      new_customer = Stripe::Customer.create({ email: credit_card.user.email },
                                             stripe_account: connected_account_id)
      attach_payment_method_to_customer(new_payment_method.id,
                                        new_customer.id,
                                        connected_account_id)

      [new_customer.id, new_payment_method.id]
    end

    private

    def clone_payment_method(credit_card, connected_account_id)
      platform_acct_payment_method_id = credit_card.gateway_payment_profile_id
      customer_id = credit_card.gateway_customer_profile_id

      Stripe::PaymentMethod.create({ customer: customer_id,
                                     payment_method: platform_acct_payment_method_id },
                                   stripe_account: connected_account_id)
    end

    def attach_payment_method_to_customer(payment_method_id, customer_id, connected_account_id)
      Stripe::PaymentMethod.attach(payment_method_id,
                                   { customer: customer_id },
                                   stripe_account: connected_account_id)
    end
  end
end
