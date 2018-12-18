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
      case source
      when Spree::LineItem
        tax_category = originator.inherits_tax_category? ? source.product.tax_category : originator.tax_category
        tax_category ? tax_category.tax_rates.match(source.order) : []
      when Spree::Order
        originator.tax_category ? originator.tax_category.tax_rates.match(source) : []
      end
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
