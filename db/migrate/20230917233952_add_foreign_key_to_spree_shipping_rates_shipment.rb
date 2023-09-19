class AddForeignKeyToSpreeShippingRatesShipment < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :spree_shipping_rates, :spree_shipments, on_delete: :cascade
  end
end
