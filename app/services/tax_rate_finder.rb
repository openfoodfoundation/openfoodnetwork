# Finds tax rates on which an adjustment is based on.
# For example a packaging fee may contain VAT. This service finds the VAT rate
# for the tax included in the packaging fee.
class TaxRateFinder
  # @return [Array<Spree::TaxRate>]
  def tax_rates(originator, source, amount, included_tax)
    find_associated_tax_rate(originator, source) ||
      find_closest_tax_rates_from_included_tax(amount, included_tax)
  end

  private

  def find_associated_tax_rate(originator, source)
    case originator
    when Spree::TaxRate
      [originator]
    when EnterpriseFee
      enterprise_fee_tax_rates(originator, source)
    end
  end

  def enterprise_fee_tax_rates(enterprise_fee, source)
    case source
    when Spree::LineItem
      tax_category = line_item_tax_category(enterprise_fee, source)
      tax_category ? tax_category.tax_rates.match(source.order) : []
    when Spree::Order
      enterprise_fee.tax_category ? enterprise_fee.tax_category.tax_rates.match(source) : []
    end
  end

  def line_item_tax_category(enterprise_fee, line_item)
    if enterprise_fee.inherits_tax_category?
      line_item.product.tax_category
    else
      enterprise_fee.tax_category
    end
  end

  # shipping fees and adjustments created from the admin panel have
  # taxes set at creation in the included_tax field without relation
  # to the corresponding TaxRate, so we look for the closest one
  def find_closest_tax_rates_from_included_tax(amount, included_tax)
    approximation = (included_tax / (amount - included_tax))
    return [] if approximation.infinite? || approximation.zero?
    [Spree::TaxRate.order("ABS(amount - #{approximation})").first]
  end
end
