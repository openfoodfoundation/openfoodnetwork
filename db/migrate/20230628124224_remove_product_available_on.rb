class RemoveProductAvailableOn < ActiveRecord::Migration[7.0]
  def change
    remove_column :spree_products, :available_on
  end
end
