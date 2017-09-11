Spree::CreditCard.class_eval do
  # Allows user to submit these attributes with checkout request
  # Required to be able to correctly store details for token-based charges
  # Obviously can be removed once we are using strong params
  attr_accessible :cc_type, :last_digits

  # For holding customer preference in memory
  attr_accessible :save_requested_by_customer
  attr_writer :save_requested_by_customer

  # Should be able to remove once we reach Spree v2.2.0
  # https://github.com/spree/spree/commit/411010f3975c919ab298cb63962ee492455b415c
  belongs_to :payment_method

  belongs_to :user

  # Allows us to use a gateway_payment_profile_id to store Stripe Tokens
  # Should be able to remove once we reach Spree v2.2.0
  # Commit: https://github.com/spree/spree/commit/5a4d690ebc64b264bf12904a70187e7a8735ef3f
  # See also: https://github.com/spree/spree_gateway/issues/111
  def has_payment_profile? # rubocop:disable Style/PredicateName
    gateway_customer_profile_id.present? || gateway_payment_profile_id.present?
  end

  def save_requested_by_customer?
    !!@save_requested_by_customer
  end
end
