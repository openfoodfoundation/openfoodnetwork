# Finds tax rates on which an adjustment is based on.
# For example a packaging fee may contain VAT. This service finds the VAT rate
# for the tax included in the packaging fee.
class TaxRateFinder
  # @return [Array<Spree::TaxRate>]
  def self.tax_rates_of(adjustment)
    new.tax_rates(
      adjustment.originator,
      adjustment.adjustable,
      adjustment.amount,
      adjustment.included_tax
    )
  end

  # @return [Array<Spree::TaxRate>]
  def tax_rates(originator, adjustable, amount, included_tax)
    find_associated_tax_rate(originator, adjustable) ||
      find_closest_tax_rates_from_included_tax(amount, included_tax)
  end

  private

  def find_associated_tax_rate(originator, adjustable)
    case originator
    when Spree::TaxRate
      [originator]
    when EnterpriseFee
      enterprise_fee_tax_rates(originator, adjustable)
    end
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
      line_item.product.tax_category
    else
      enterprise_fee.tax_category
    end
  end

  # There are two cases in which a line item is not associated to a tax rate.
  #
  # 1. Shipping fees and adjustments created from the admin panel have taxes set
  #    at creation in the included_tax field without relation to the
  #    corresponding TaxRate.
  # 2. Removing line items from an order doesn't always remove the associated
  #    enterprise fees. These orphaned fees don't have a line item any more to
  #    find the item's tax rate.
  #
  # In these cases we try to find the used tax rate based on the included tax.
  # For example, if the included tax is 10% of the adjustment, we look for a tax
  # rate of 10%. Due to rounding errors, the included tax may be 9.9% of the
  # adjustment. That's why we call it an approximation of the tax rate and look
  # for the closest and hopefully find the 10% tax rate.
  #
  # This attempt can fail.
  #
  # - If an admin created an adjustment with a miscalculated included tax then
  #   we don't know which tax rate the admin intended to use.
  # - An admin may also enter included tax that doesn't correspond to any tax
  #   rate in the system. They may enter a fee of $1.2 with tax of $0.2, but
  #   that doesn't mean that there is a 20% tax rate in the database.
  # - The used tax rate may also have been deleted. Maybe the tax law changed.
  #
  # In either of these cases, we will find a tax rate that doesn't correspond
  # to the included tax.
  def find_closest_tax_rates_from_included_tax(amount, included_tax)
    approximation = (included_tax / (amount - included_tax))
    return [] if approximation.infinite? || approximation.zero? || approximation.nan?

    [Spree::TaxRate.order("ABS(amount - #{approximation})").first]
  end
end
