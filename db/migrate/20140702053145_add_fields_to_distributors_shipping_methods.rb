class AddFieldsToDistributorsShippingMethods < ActiveRecord::Migration
  class DistributorShippingMethod < ActiveRecord::Base
    self.table_name = "distributors_shipping_methods"
  end

  def up
    add_column :distributors_shipping_methods, :id, :primary_key
    add_column :distributors_shipping_methods, :created_at, :datetime
    add_column :distributors_shipping_methods, :updated_at, :datetime

    DistributorShippingMethod.reset_column_information
    DistributorShippingMethod.update_all created_at: Time.zone.now, updated_at: Time.zone.now

    change_column :distributors_shipping_methods, :created_at, :datetime, null: false
    change_column :distributors_shipping_methods, :updated_at, :datetime, null: false
  end

  def down
    remove_column :distributors_shipping_methods, :id
    remove_column :distributors_shipping_methods, :created_at
    remove_column :distributors_shipping_methods, :updated_at
  end
end
