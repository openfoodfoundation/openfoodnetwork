# frozen_string_literal: true

# EnterpriseFeeAdjustments represent a collection of enterprise fee adjustments
#
class EnterpriseFeeAdjustments
  def initialize(adjustments)
    @adjustments = adjustments
  end

  def total_additional_tax
    @adjustments.sum { |enterprise_fee| enterprise_fee.additional_tax_total.to_f }
  end

  def total_included_tax
    @adjustments.sum { |enterprise_fee| enterprise_fee.included_tax_total.to_f }
  end
end
