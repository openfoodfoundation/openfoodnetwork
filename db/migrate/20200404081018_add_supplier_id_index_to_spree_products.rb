class AddSupplierIdIndexToSpreeProducts < ActiveRecord::Migration[4.2]
  def change
    add_index :spree_products, :supplier_id
  end
end
