class AddForeignKeyToSpreeShippingRatesShippingMethod < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :spree_shipping_rates, :spree_shipping_methods, on_delete: :cascade
  end
end
