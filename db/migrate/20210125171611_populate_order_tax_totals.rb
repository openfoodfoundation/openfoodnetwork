class PopulateOrderTaxTotals < ActiveRecord::Migration[4.2]
  def up
    # Updates new order tax total fields (additional_tax_total and included_tax_total).
    # Sums the relevant values from associated adjustments and updates the two columns.
    update_orders
  end

  def update_orders
    sql = <<-SQL
      UPDATE spree_orders
      SET additional_tax_total = totals.additional,
          included_tax_total = totals.included
      FROM (
        SELECT spree_orders.id AS order_id,
          COALESCE(additional_adjustments.sum, 0) AS additional,
          COALESCE(included_adjustments.sum, 0) AS included
        FROM spree_orders
        LEFT JOIN (
          SELECT order_id, SUM(amount) AS sum
          FROM spree_adjustments
          WHERE spree_adjustments.originator_type = 'Spree::TaxRate'
          AND spree_adjustments.included IS FALSE
          GROUP BY order_id
        ) additional_adjustments ON spree_orders.id = additional_adjustments.order_id
        LEFT JOIN (
          SELECT order_id, SUM(included_tax) as sum
          FROM spree_adjustments
          WHERE spree_adjustments.included_tax IS NOT NULL
          AND (
            spree_adjustments.originator_type = 'Spree::ShippingMethod'
            OR spree_adjustments.originator_type = 'EnterpriseFee'
            OR (
              spree_adjustments.originator_type = 'Spree::TaxRate'
              AND spree_adjustments.adjustable_type = 'Spree::LineItem'
            )
            OR (
              spree_adjustments.originator_type IS NULL
              AND spree_adjustments.adjustable_type = 'Spree::Order'
              AND spree_adjustments.included IS FALSE
            )
          )
          GROUP BY order_id
        ) included_adjustments ON spree_orders.id = included_adjustments.order_id
      ) totals
      WHERE totals.order_id = spree_orders.id
    SQL

    ActiveRecord::Base.connection.execute(sql)
  end
end
