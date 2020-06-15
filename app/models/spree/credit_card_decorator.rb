Spree::CreditCard.class_eval do
  # For holding customer preference in memory
  attr_writer :save_requested_by_customer

  # Should be able to remove once we reach Spree v2.2.0
  # https://github.com/spree/spree/commit/411010f3975c919ab298cb63962ee492455b415c
  belongs_to :payment_method

  belongs_to :user

  after_create :ensure_single_default_card
  after_save :ensure_single_default_card, if: :default_card_needs_updating?

  # Allows us to use a gateway_payment_profile_id to store Stripe Tokens
  # Should be able to remove once we reach Spree v2.2.0
  # Commit: https://github.com/spree/spree/commit/5a4d690ebc64b264bf12904a70187e7a8735ef3f
  # See also: https://github.com/spree/spree_gateway/issues/111
  def has_payment_profile? # rubocop:disable Naming/PredicateName
    gateway_customer_profile_id.present? || gateway_payment_profile_id.present?
  end

  def save_requested_by_customer?
    !!@save_requested_by_customer
  end

  private

  def reusable?
    gateway_customer_profile_id.present?
  end

  def default_missing?
    !user.credit_cards.exists?(is_default: true)
  end

  def default_card_needs_updating?
    is_default_changed? || gateway_customer_profile_id_changed?
  end

  def ensure_single_default_card
    return unless user
    return unless is_default? || (reusable? && default_missing?)

    user.credit_cards.update_all(['is_default=(id=?)', id])
    self.is_default = true
  end
end
