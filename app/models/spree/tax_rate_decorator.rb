Spree::TaxRate.class_eval do
  class << self
    def match_with_sales_tax_registration(order)
      return [] unless order.distributor.charges_sales_tax
      match_without_sales_tax_registration(order)
    end
    alias_method_chain :match, :sales_tax_registration
  end


  def adjust_with_included_tax(order)
    adjust_without_included_tax(order)

    order.reload
    (order.adjustments.tax + order.price_adjustments).each do |a|
      a.set_absolute_included_tax! a.amount
    end
  end
  alias_method_chain :adjust, :included_tax
end
