module Spree
  TaxRate.class_eval do
    class << self
      def match_with_sales_tax_registration(order)
        return [] if order.distributor && !order.distributor.charges_sales_tax
        match_without_sales_tax_registration(order)
      end
      alias_method_chain :match, :sales_tax_registration
    end


    def adjust_with_included_tax(order)
      adjust_without_included_tax(order)

      order.adjustments(:reload)
      order.line_items(:reload)
      (order.adjustments.tax + order.price_adjustments).each do |a|
        a.set_absolute_included_tax! a.amount
      end
    end
    alias_method_chain :adjust, :included_tax


    # Manually apply a TaxRate to a particular amount. TaxRates normally compute against
    # LineItems or Orders, so we mock out a line item here to fit the interface
    # that our calculator (usually DefaultTax) expects.
    def compute_tax(amount)
      product = OpenStruct.new tax_category: tax_category
      line_item = LineItem.new quantity: 1
      line_item.define_singleton_method(:product) { product }
      line_item.define_singleton_method(:price) { amount }

      # Tax on adjustments (represented by the included_tax field) is always inclusive of
      # tax. However, there's nothing to stop an admin from setting one up with a tax rate
      # that's marked as not inclusive of tax, and that would result in the DefaultTax
      # calculator generating a slightly incorrect value. Therefore, we treat the tax
      # rate as inclusive of tax for the calculations below, regardless of its original
      # setting.
      with_tax_included_in_price do
        calculator.compute line_item
      end
    end


    private

    def with_tax_included_in_price
      old_included_in_price = self.included_in_price

      self.included_in_price = true
      calculator.calculable.included_in_price = true

      result = yield

    ensure
      self.included_in_price = old_included_in_price
      calculator.calculable.included_in_price = old_included_in_price

      result
    end
  end
end
