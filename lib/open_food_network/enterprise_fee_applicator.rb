module OpenFoodNetwork
  class EnterpriseFeeApplicator < Struct.new(:enterprise_fee, :variant, :role)
    def create_line_item_adjustment(line_item)
      a = enterprise_fee.create_locked_adjustment(line_item_adjustment_label, line_item.order, line_item, true)

      AdjustmentMetadata.create! adjustment: a, enterprise: enterprise_fee.enterprise, fee_name: enterprise_fee.name, fee_type: enterprise_fee.fee_type, enterprise_role: role

      a.set_absolute_included_tax! adjustment_tax(line_item, a)
    end

    def create_order_adjustment(order)
      a = enterprise_fee.create_locked_adjustment(order_adjustment_label, order, order, true)

      AdjustmentMetadata.create! adjustment: a, enterprise: enterprise_fee.enterprise, fee_name: enterprise_fee.name, fee_type: enterprise_fee.fee_type, enterprise_role: role

      a.set_absolute_included_tax! adjustment_tax(order, a)
    end


    private

    def line_item_adjustment_label
      "#{variant.product.name} - #{base_adjustment_label}"
    end

    def order_adjustment_label
      "Whole order - #{base_adjustment_label}"
    end

    def base_adjustment_label
      "#{enterprise_fee.fee_type} fee by #{role} #{enterprise_fee.enterprise.name}"
    end

    def adjustment_tax(adjustable, adjustment)
      tax_rates = rates_for(adjustable)

      tax_rates.select(&:included_in_price).sum do |rate|
        rate.compute_tax adjustment.amount
      end
    end

    def rates_for(adjustable)
      case adjustable
      when Spree::LineItem
        tax_category = enterprise_fee.inherits_tax_category? ? adjustable.product.tax_category : enterprise_fee.tax_category
        return tax_category ? tax_category.tax_rates.match(adjustable.order) : []
      when Spree::Order
        return enterprise_fee.tax_category ? enterprise_fee.tax_category.tax_rates.match(adjustable) : []
      end
    end
  end
end
