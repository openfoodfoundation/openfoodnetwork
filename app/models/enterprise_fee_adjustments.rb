# frozen_string_literal: true

# EnterpriseFeeAdjustments represent a collection of enterprise fee adjustments
#
class EnterpriseFeeAdjustments
  def initialize(adjustments)
    @adjustments = adjustments
  end

  def total_additional_tax
    @adjustments.reduce(0.0) do |sum, enterprise_fee|
      sum += enterprise_fee.additional_tax_total if enterprise_fee&.adjustments

      sum
    end
  end

  def total_included_tax
    @adjustments.reduce(0.0) do |sum, enterprise_fee|
      sum += enterprise_fee.included_tax_total if enterprise_fee&.adjustments

      sum
    end
  end
end
