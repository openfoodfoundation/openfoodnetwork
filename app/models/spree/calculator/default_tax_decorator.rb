require 'open_food_network/enterprise_fee_calculator'

Spree::Calculator::DefaultTax.class_eval do

  private

  # Override this method to enable calculation of tax for
  # enterprise fees with tax rates where included_in_price = false
  def compute_order(order)
    matched_line_items = order.line_items.select do |line_item|
      line_item.product.tax_category == rate.tax_category
    end

    line_items_total = matched_line_items.sum(&:total)

    # Added this line
    calculator = OpenFoodNetwork::EnterpriseFeeCalculator.new(order.distributor, order.order_cycle)

    # Added this block, finds relevant fees for each line_item, calculates the tax on them, and returns the total tax
    per_item_fees_total = order.line_items.sum do |line_item|
      calculator.send(:per_item_enterprise_fee_applicators_for, line_item.variant)
      .select { |applicator| applicator.enterprise_fee.tax_category == rate.tax_category }
      .sum { |applicator| applicator.enterprise_fee.compute_amount(line_item) }
    end

    # Added this block, finds relevant fees for whole order, calculates the tax on them, and returns the total tax
    per_order_fees_total = calculator.send(:per_order_enterprise_fee_applicators_for, order)
      .select { |applicator| applicator.enterprise_fee.tax_category == rate.tax_category }
      .sum { |applicator| applicator.enterprise_fee.compute_amount(order) }

    # round_to_two_places(line_items_total * rate.amount) # Removed this line

    # Added this block
    [line_items_total, per_item_fees_total, per_order_fees_total].sum do |total|
      round_to_two_places(total * rate.amount)
    end
  end

end
