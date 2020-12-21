# frozen_string_literal: true

# Here we destroy (on Stripe) any clones that we have created for a platform card.
# See CreditCardCloner for details.

# This is useful when the platform card is deleted (and needs to happen before the
# platform card is deleted on Stripe).

module Stripe
  class CreditCardCloneDestroyer
    def destroy_clones(card)
      card.user.customers.each do |customer|
        next unless stripe_account = customer.enterprise.stripe_account&.stripe_user_id

        customer_id, _payment_method_id =
          Stripe::CreditCardCloneFinder.new(card, stripe_account).find_cloned_card
        next unless customer_id

        stripe_customer = Stripe::Customer.retrieve(customer_id, stripe_account: stripe_account)
        stripe_customer.delete if stripe_customer && !stripe_customer.deleted?
      end
    end
  end
end
