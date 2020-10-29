# frozen_string_literal: true

class RecurringPayments
  def self.setup_for(customer)
    return unless card = customer.user.default_card
    return unless payment_method = card.gateway_payment_profile_id
    return unless customer_profile_id = card.gateway_customer_profile_id

    stripe_account = customer.enterprise.stripe_account&.stripe_user_id
    setup_intent = Stripe::SetupIntent.create(
      payment_method: payment_method, customer: customer_profile_id, on_behalf_of: stripe_account
    )
    setup_intent.client_secret
  end
end
