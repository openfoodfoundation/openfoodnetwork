# frozen_string_literal: true

require 'active_support/concern'

module OrderValidations
  extend ActiveSupport::Concern

  private

  def disallow_guest_order
    return unless using_guest_checkout? && registered_email?

    errors.add(:email, I18n.t('devise.failure.already_registered'))
  end

  # Check that line_items in the current order are available from a newly selected distribution
  def products_available_from_new_distribution
    return if OrderCycleDistributedVariants.new(order_cycle, distributor)
      .distributes_order_variants?(self)

    errors.add(:base, I18n.t(:spree_order_availability_error))
  end

  # Determine if email is required (we don't want validation errors before we hit the checkout)
  def require_email
    true unless (new_record? || cart?) && !checkout_processing
  end

  def ensure_line_items_present
    return if line_items.present?

    errors.add(:base, Spree.t(:there_are_no_items_for_this_order))
    false
  end

  def ensure_available_shipping_rates
    return unless shipments.empty? || shipments.any? { |shipment| shipment.shipping_rates.blank? }

    errors.add(:base, Spree.t(:items_cannot_be_shipped))
    false
  end
end
