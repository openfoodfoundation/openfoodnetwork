class RemoveShippingMethodFromProductDistribution < ActiveRecord::Migration
  def up
    remove_column :product_distributions, :shipping_method_id
  end

  def down
    add_column :product_distributions, :shipping_method_id, :integer
  end
end
