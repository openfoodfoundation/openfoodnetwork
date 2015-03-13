Spree::TaxRate.class_eval do
  def adjust_with_included_tax(order)
    adjust_without_included_tax(order)

    order.reload
    (order.adjustments.tax + order.price_adjustments).each do |a|
      a.set_absolute_included_tax! a.amount
    end
  end

  alias_method_chain :adjust, :included_tax
end
