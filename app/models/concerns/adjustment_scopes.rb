# frozen_string_literal: true

module AdjustmentScopes
  extend ActiveSupport::Concern

  PAYMENT_FEE_SCOPE = { originator_type: 'Spree::PaymentMethod' }.freeze
  SHIPPING_SCOPE = { originator_type: 'Spree::ShippingMethod' }.freeze
  ELIGIBLE_SCOPE = { eligible: true }.freeze

  def payment_fee_scope
    PAYMENT_FEE_SCOPE
  end

  def shipping_scope
    SHIPPING_SCOPE
  end

  def eligible_scope
    ELIGIBLE_SCOPE
  end
end
