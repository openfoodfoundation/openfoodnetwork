class AddEnableStandingOrdersToEnterprises < ActiveRecord::Migration
  def change
    add_column :enterprises, :enable_standing_orders, :boolean, default: false, null: false
  end
end
