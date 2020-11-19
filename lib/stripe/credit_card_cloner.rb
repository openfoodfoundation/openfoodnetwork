# frozen_string_literal: true

# Here we clone (or find a clone of)
#   - a card (card_*) or payment_method (pm_*) stored (in a customer) in a platform account into
#   - a payment method (pm_*) (in a new customer) in a connected account
#
# This is required when using the Stripe Payment Intents API:
#   - the customer and payment methods are stored in the platform account
#       so that they can be re-used across multiple sellers
#   - when a card needs to be charged, we need to clone (or find the clone)
#       in the seller's stripe account
#
# To avoid creating a new clone of the card/customer each time the card is charged or
# authorized (e.g. for SCA), we attach metadata { clone: true } to the card the first time we
# clone it and look for a card with the same fingerprint (hash of the card number) and
# that metadata key to avoid cloning it multiple times.

module Stripe
  class CreditCardCloner
    def find_or_clone(credit_card, connected_account_id)
      if card = find_cloned_card(credit_card, connected_account_id)
        card
      else
        clone(credit_card, connected_account_id)
      end
    end

    private

    def clone(credit_card, connected_account_id)
      new_payment_method = clone_payment_method(credit_card, connected_account_id)

      # If no customer is given, it will clone the payment method only
      return [nil, new_payment_method.id] if credit_card.gateway_customer_profile_id.blank?

      new_customer = Stripe::Customer.create({ email: credit_card.user.email },
                                             stripe_account: connected_account_id)
      attach_payment_method_to_customer(new_payment_method.id,
                                        new_customer.id,
                                        connected_account_id)

      add_metadata_to_payment_method(new_payment_method.id, connected_account_id)

      [new_customer.id, new_payment_method.id]
    end

    def find_cloned_card(card, connected_account_id)
      matches = []
      return matches unless fingerprint = fingerprint_for_card(card)

      find_customers(card.user.email, connected_account_id).each do |customer|
        find_payment_methods(customer.id, connected_account_id).each do |payment_method|
          if payment_method_is_clone?(payment_method, fingerprint)
            matches << [customer.id, payment_method.id]
          end
        end
      end

      matches.first
    end

    def payment_method_is_clone?(payment_method, fingerprint)
      payment_method.card.fingerprint == fingerprint && payment_method.metadata["ofn-clone"]
    end

    def fingerprint_for_card(card)
      Stripe::PaymentMethod.retrieve(card.gateway_payment_profile_id).card.fingerprint
    end

    def find_customers(email, connected_account_id)
      starting_after = nil
      customers = []

      loop do
        response = Stripe::Customer.list({ email: email, starting_after: starting_after },
                                         stripe_account: connected_account_id)
        customers += response.data
        break unless response.has_more

        starting_after = response.data.last.id
      end
      customers
    end

    def find_payment_methods(customer_id, connected_account_id)
      starting_after = nil
      payment_methods = []

      loop do
        options = { customer: customer_id, type: 'card', starting_after: starting_after }
        response = Stripe::PaymentMethod.list(options, stripe_account: connected_account_id)
        payment_methods += response.data
        break unless response.has_more

        starting_after = response.data.last.id
      end
      payment_methods
    end

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

    def add_metadata_to_payment_method(payment_method_id, connected_account_id)
      Stripe::PaymentMethod.update(payment_method_id,
                                   { metadata: { "ofn-clone": true } },
                                   stripe_account: connected_account_id)
    end
  end
end
