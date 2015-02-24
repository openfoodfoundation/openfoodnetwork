class AddTemperatureControlledToSpreeShippingCategories < ActiveRecord::Migration
  def change
    add_column :spree_shipping_categories, :temperature_controlled, :boolean
  end
end
