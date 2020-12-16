module AdjustmentHandling
  extend ActiveSupport::Concern

  # Creates a new adjustment for the target object
  #   (which is any class that has_many :adjustments) and sets amount based on the
  #   calculator as applied to the given calculable (Order, LineItems[], Shipment, etc.)
  # By default the adjustment will not be considered mandatory
  def create_adjustment(label, order, source, adjustable, mandatory = false, state = "closed")
    amount = compute_amount(adjustable, source)
    return if amount.zero? && !mandatory

    self.adjustments.create(
      amount: amount,
      source: source,
      adjustable: adjustable,
      order: order,
      label: label,
      mandatory: mandatory,
      state: state
    )
  end

  # Calculate the amount to be used when creating an adjustment
  def compute_amount(calculable, source = self)
    # Adjustment calculations done on Spree::Shipment objects MUST
    # be done on their to_package'd variants instead
    # It's only the package that contains the correct information.
    # See https://github.com/spree/spree_active_shipping/pull/96 et. al
    calculable.to_package if calculable.is_a?(Spree::Shipment)
    source.calculator.compute(calculable)
  end
end
