class AddFieldsToDistributorsShippingMethods < ActiveRecord::Migration
  def change
    add_column :distributors_shipping_methods, :id, :primary_key
    add_column :distributors_shipping_methods, :created_at, :datetime
    add_column :distributors_shipping_methods, :updated_at, :datetime
  end
end
