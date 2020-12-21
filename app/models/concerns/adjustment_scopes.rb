module AdjustmentScopes
  extend ActiveSupport::Concern

  PAYMENT_FEE_SCOPE = { adjustable_type: 'Spree::Payment' }.freeze
  SHIPPING_SCOPE = { adjustable_type: 'Spree::Shipment' }.freeze
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
