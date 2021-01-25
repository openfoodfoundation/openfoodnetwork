class PopulateOrderTaxTotals < ActiveRecord::Migration
  def up
    Spree::Order.where(additional_tax_total: 0, included_tax_total: 0).
      find_each(batch_size: 500) do |order|

      additional_tax_total = order.all_adjustments.tax.additional.sum(:amount)

      included_tax_total = order.line_item_adjustments.tax.sum(:included_tax) +
        order.all_adjustments.enterprise_fee.sum(:included_tax) +
        order.adjustments.shipping.sum(:included_tax)

      order.update_columns(
        additional_tax_total: additional_tax_total,
        included_tax_total: included_tax_total
      )
    end
  end
end
