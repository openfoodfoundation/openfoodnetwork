module OpenFoodNetwork
  class EnterpriseFeeApplicator < Struct.new(:enterprise_fee, :variant, :role)
    def create_line_item_adjustment(line_item)
      a = enterprise_fee.create_locked_adjustment(line_item_adjustment_label, line_item.order, line_item, true)

      AdjustmentMetadata.create! adjustment: a, enterprise: enterprise_fee.enterprise, fee_name: enterprise_fee.name, fee_type: enterprise_fee.fee_type, enterprise_role: role
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

    def adjustment_tax(order, adjustment)
      enterprise_fee.tax_category.tax_rates.match(order).sum do |rate|
        compute_tax rate, adjustment.amount
      end
    end

    # Apply a TaxRate to a particular amount. TaxRates normally compute against
    # LineItems or Orders, so we mock out a line item here to fit the interface
    # that our calculator (usually DefaultTax) expects.
    def compute_tax(tax_rate, amount)
      product = OpenStruct.new tax_category: tax_rate.tax_category
      line_item = Spree::LineItem.new quantity: 1
      line_item.define_singleton_method(:product) { product }
      line_item.define_singleton_method(:price) { amount }

      # The enterprise fee adjustments for which we're calculating tax are always inclusive of
      # tax. However, there's nothing to stop an admin from setting one up with a tax rate
      # that's marked as not inclusive of tax, and that would result in the DefaultTax
      # calculator generating a slightly incorrect value. Therefore, we treat the tax
      # rate as inclusive of tax for the calculations below, regardless of its original
      # setting.
      with_tax_included_in_price(tax_rate) do
        tax_rate.calculator.compute line_item
      end
    end

    def with_tax_included_in_price(tax_rate)
      old_included_in_price = tax_rate.included_in_price

      tax_rate.included_in_price = true
      tax_rate.calculator.calculable.included_in_price = true

      result = yield

      tax_rate.included_in_price = old_included_in_price
      tax_rate.calculator.calculable.included_in_price = old_included_in_price

      result
    end
  end
end

