# frozen_string_literal: true

# Finds tax rates on which an adjustment is based on.
# For example a packaging fee may contain VAT. This service finds the VAT rate
# for the tax included in the packaging fee.
class TaxRateFinder
  # @return [Array<Spree::TaxRate>]
  def self.tax_rates_of(adjustment)
    new.tax_rates(adjustment.originator, adjustment.adjustable)
  end

  # @return [Array<Spree::TaxRate>]
  def tax_rates(originator, adjustable)
    find_associated_tax_rate(originator, adjustable) || []
  end

  private

  def find_associated_tax_rate(originator, adjustable)
    case originator
    when Spree::TaxRate
      [originator]
    when Spree::ShippingMethod
      shipping_method_fee_tax_rates(originator, adjustable)
    when EnterpriseFee
      enterprise_fee_tax_rates(originator, adjustable)
    end
  end

  def shipping_method_fee_tax_rates(shipping_method, _adjustable)
    shipping_method.tax_category ? shipping_method.tax_category.tax_rates : []
  end

  def enterprise_fee_tax_rates(enterprise_fee, adjustable)
    case adjustable
    when Spree::LineItem
      tax_category = line_item_tax_category(enterprise_fee, adjustable)
      tax_category ? tax_category.tax_rates.match(adjustable.order) : []
    when Spree::Order
      enterprise_fee.tax_category ? enterprise_fee.tax_category.tax_rates.match(adjustable) : []
    end
  end

  def line_item_tax_category(enterprise_fee, line_item)
    if enterprise_fee.inherits_tax_category?
      line_item.variant.tax_category
    else
      enterprise_fee.tax_category
    end
  end
end
