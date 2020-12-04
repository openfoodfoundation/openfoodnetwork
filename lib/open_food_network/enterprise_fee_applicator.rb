module OpenFoodNetwork
  class EnterpriseFeeApplicator < Struct.new(:enterprise_fee, :variant, :role)
    def create_line_item_adjustment(line_item)
      # This all needs a big refactor after it's working correctly...
      create_adjustment(line_item_adjustment_label, line_item.order, line_item, line_item, line_item)
    end

    def create_order_adjustment(order)
      create_adjustment(order_adjustment_label, order, order, order, order)
    end

    private

    def create_adjustment(label, order, target, calculable, adjustable)
      adjustment = create_enterprise_fee_adjustment(label, order, target, calculable, adjustable)

      AdjustmentMetadata.create! adjustment: adjustment, enterprise: enterprise_fee.enterprise, fee_name: enterprise_fee.name, fee_type: enterprise_fee.fee_type, enterprise_role: role

      adjustment.set_absolute_included_tax! adjustment_tax(adjustment)
    end

    def create_enterprise_fee_adjustment(label, order, target, calculable, adjustable)
      adjustment = enterprise_fee.create_adjustment(label, order, target, calculable, adjustable, true)

      adjustment
    end

    def line_item_adjustment_label
      "#{variant.product.name} - #{base_adjustment_label}"
    end

    def order_adjustment_label
      "#{I18n.t(:enterprise_fee_whole_order)} - #{base_adjustment_label}"
    end

    def base_adjustment_label
      I18n.t(:enterprise_fee_by, type: enterprise_fee.fee_type, role: role, enterprise_name: enterprise_fee.enterprise.name)
    end

    def adjustment_tax(adjustment)
      tax_rate = enterprise_fee&.tax_category&.tax_rates&.first
      # A given TaxCategory object can have lots of tax rates...
      # Maybe enterprise should know what rate it is using...?

      if tax_rate.present?
        # tax_rate.compute_amount(adjustment.adjustable)
        tax_rate.compute_tax(adjustment.amount)
      else
        0
      end

      # TaxRateFinder needs work...

      # tax_rates = TaxRateFinder.tax_rates_of(adjustment)
      #
      # tax_rates.select(&:included_in_price).sum do |rate|
      #   rate.compute_tax adjustment.amount
      # end
    end
  end
end
