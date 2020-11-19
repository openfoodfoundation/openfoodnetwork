# frozen_string_literal: true

class RecurringPayments
  def self.setup_for(customer)
    return unless card = customer.user.default_card

    stripe_account = customer.enterprise.stripe_account&.stripe_user_id

    customer_id, payment_method_id =
      Stripe::CreditCardCloner.new.find_or_clone(card, stripe_account)
    setup_intent = Stripe::SetupIntent.create(
      { payment_method: payment_method_id, customer: customer_id },
      { stripe_account: stripe_account }
    )
    setup_intent.client_secret
  end
end
