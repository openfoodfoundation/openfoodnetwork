Spree::CreditCard.class_eval do
  # Should be able to remove once we reach Spree v2.2.0
  # https://github.com/spree/spree/commit/411010f3975c919ab298cb63962ee492455b415c
  belongs_to :payment_method

  # Allows us to use a gateway_payment_profile_id to store Stripe Tokens
  # Should be able to remove once we reach Spree v2.2.0
  # Commit: https://github.com/spree/spree/commit/5a4d690ebc64b264bf12904a70187e7a8735ef3f
  # See also: https://github.com/spree/spree_gateway/issues/111
  def has_payment_profile?
    gateway_customer_profile_id.present? || gateway_payment_profile_id.present?
  end
end
