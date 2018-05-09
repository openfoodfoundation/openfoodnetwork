# Encapsulation of all of the validation logic required for subscriptions
# Public interface consists of #valid? method provided by ActiveModel::Validations
# and #json_errors which compiles a serializable hash of errors

class SubscriptionValidator
  include ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  attr_reader :subscription

  validates_presence_of :shop, :customer, :schedule, :shipping_method, :payment_method
  validates_presence_of :bill_address, :ship_address, :begins_at
  validate :shipping_method_allowed?
  validate :payment_method_allowed?
  validate :payment_method_type_allowed?
  validate :ends_at_after_begins_at?
  validate :customer_allowed?
  validate :schedule_allowed?
  validate :credit_card_ok?
  validate :subscription_line_items_present?
  validate :requested_variants_available?

  delegate :shop, :customer, :schedule, :shipping_method, :payment_method, to: :subscription
  delegate :bill_address, :ship_address, :begins_at, :ends_at, to: :subscription
  delegate :credit_card, :credit_card_id, to: :subscription
  delegate :subscription_line_items, to: :subscription

  def initialize(subscription)
    @subscription = subscription
  end

  def json_errors
    errors.messages.each_with_object({}) do |(k, v), errors|
      errors[k] = v.map { |msg| build_msg_from(k, msg) }
    end
  end

  private

  def shipping_method_allowed?
    return unless shipping_method
    return if shipping_method.distributors.include?(shop)
    errors.add(:shipping_method, :not_available_to_shop, shop: shop.name)
  end

  def payment_method_allowed?
    return unless payment_method
    return if payment_method.distributors.include?(shop)
    errors.add(:payment_method, :not_available_to_shop, shop: shop.name)
  end

  def payment_method_type_allowed?
    return unless payment_method
    return if Subscription::ALLOWED_PAYMENT_METHOD_TYPES.include? payment_method.type
    errors.add(:payment_method, :invalid_type)
  end

  def ends_at_after_begins_at?
    # Only validates ends_at if it is present
    return if begins_at.blank? || ends_at.blank?
    return if ends_at > begins_at
    errors.add(:ends_at, :after_begins_at)
  end

  def customer_allowed?
    return unless customer
    return if customer.enterprise == shop
    errors.add(:customer, :does_not_belong_to_shop, shop: shop.name)
  end

  def schedule_allowed?
    return unless schedule
    return if schedule.coordinators.include?(shop)
    errors.add(:schedule, :not_coordinated_by_shop, shop: shop.name)
  end

  def credit_card_ok?
    return unless customer && payment_method
    return unless payment_method.type == "Spree::Gateway::StripeConnect"
    return errors.add(:credit_card, :charges_not_allowed) unless customer.allow_charges
    return if customer.user.andand.default_card.present?
    errors.add(:credit_card, :no_default_card)
  end

  def subscription_line_items_present?
    return if subscription_line_items.reject(&:marked_for_destruction?).any?
    errors.add(:subscription_line_items, :at_least_one_product)
  end

  def requested_variants_available?
    subscription_line_items.each { |sli| verify_availability_of(sli.variant) }
  end

  def verify_availability_of(variant)
    return if available_variant_ids.include? variant.id
    name = "#{variant.product.name} - #{variant.full_name}"
    errors.add(:subscription_line_items, :not_available, name: name)
  end

  # TODO: Extract this into a separate class
  def available_variant_ids
    @available_variant_ids ||=
      Spree::Variant.joins(exchanges: { order_cycle: :schedules })
        .where(id: subscription_line_items.map(&:variant_id))
        .where(schedules: { id: schedule }, exchanges: { incoming: false, receiver_id: shop })
        .merge(OrderCycle.not_closed)
        .select('DISTINCT spree_variants.id')
        .pluck(:id)
  end

  def build_msg_from(k, msg)
    return msg[1..-1] if msg.starts_with?("^")
    errors.full_message(k, msg)
  end
end
