Spree::CreditCard.class_eval do
  # Allows us to use a gateway_payment_profile_id to store Stripe Tokens
  # Should be able to remove once we reach Spree v2.2.0
  # Commit: https://github.com/spree/spree/commit/5a4d690ebc64b264bf12904a70187e7a8735ef3f
  # See also: https://github.com/spree/spree_gateway/issues/111

  belongs_to :payment_method

  def has_payment_profile?
    gateway_customer_profile_id.present? || gateway_payment_profile_id.present?
  end
end
