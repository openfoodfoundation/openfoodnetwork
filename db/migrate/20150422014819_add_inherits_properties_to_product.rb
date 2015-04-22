class AddInheritsPropertiesToProduct < ActiveRecord::Migration
  def change
    add_column :spree_products, :inherits_properties, :boolean, null: false, default: true
  end
end
