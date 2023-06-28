class RemoveProductPermalink < ActiveRecord::Migration[7.0]
  def change
    remove_column :spree_products, :permalink
  end
end
