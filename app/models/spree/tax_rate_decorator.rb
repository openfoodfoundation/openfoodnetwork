Spree::TaxRate.class_eval do
  def adjust_with_included_tax(order)
    adjust_without_included_tax(order)

    (order.adjustments.tax + order.price_adjustments).each do |a|
      a.set_included_tax! 1.0
    end
  end

  alias_method_chain :adjust, :included_tax
end
