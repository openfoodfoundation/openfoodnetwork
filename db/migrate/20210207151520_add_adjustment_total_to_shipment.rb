class AddAdjustmentTotalToShipment < ActiveRecord::Migration[4.2]
  def up
    add_column :spree_shipments, :adjustment_total, :decimal,
               precision: 10, scale: 2, null: false, default: 0.0

    populate_adjustment_totals
  end

  def down
    remove_column :spree_shipments, :adjustment_total
  end

  def populate_adjustment_totals
    # Populates the new `adjustment_total` field in the spree_shipments table. Sets the value
    # to the shipment's (shipping fee) adjustment amount.

    adjustment_totals_sql = <<-SQL
      UPDATE spree_shipments
      SET adjustment_total = shipping_adjustment.fee_amount
      FROM (
        SELECT spree_adjustments.source_id AS shipment_id, spree_adjustments.amount AS fee_amount
        FROM spree_adjustments
        WHERE spree_adjustments.source_type = 'Spree::Shipment'
          AND spree_adjustments.amount <> 0
      ) shipping_adjustment
      WHERE spree_shipments.id = shipping_adjustment.shipment_id
    SQL

    ActiveRecord::Base.connection.execute(adjustment_totals_sql)
  end
end
