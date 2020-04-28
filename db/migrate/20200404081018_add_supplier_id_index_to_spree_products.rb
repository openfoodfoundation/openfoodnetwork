class AddSupplierIdIndexToSpreeProducts < ActiveRecord::Migration
  def change
    add_index :spree_products, :supplier_id
  end
end
