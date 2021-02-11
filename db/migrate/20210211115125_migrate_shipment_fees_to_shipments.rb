class MigrateShipmentFeesToShipments < ActiveRecord::Migration
  def up
    # Shipping fee adjustments currently have the order as the `adjustable` and the shipment as
    # the `source`. Both `source` and `adjustable` will now be the shipment. The `originator` is
    # the shipping method, and this is unchanged.
    Spree::Adjustment.where(originator_type: 'Spree::ShippingMethod').update_all(
      "adjustable_id = source_id, adjustable_type = 'Spree::Shipment'"
    )
  end

  def down
    # Just in case: reversing this migration requires setting the `adjustable` back to the order.
    # The type is 'Spree::Order', and the order's id is still available on the `order_id` field.
    Spree::Adjustment.where(originator_type: 'Spree::ShippingMethod').update_all(
      "adjustable_id = order_id, adjustable_type = 'Spree::Order'"
    )
  end
end
