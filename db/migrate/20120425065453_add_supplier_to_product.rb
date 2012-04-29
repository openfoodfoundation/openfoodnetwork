class AddSupplierToProduct < ActiveRecord::Migration
  def change
    add_column :spree_products, :supplier_id, :integer
  end
end
