# frozen_string_literal: true

# EnterpriseFeeAdjustments represent a collection of enterprise fee adjustments
#
class EnterpriseFeeAdjustments
  def initialize(adjustments)
    @adjustments = adjustments
  end

  # Calculate the tax portion of enterprise fee when tax excluded from price
  def total_tax
    @adjustments.reduce(0.0) do |sum, enterprise_fee|
      sum += enterprise_fee.adjustments.tax.additional.sum(:amount) if enterprise_fee&.adjustments

      sum
    end
  end
end
