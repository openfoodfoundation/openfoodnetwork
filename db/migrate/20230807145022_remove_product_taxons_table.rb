class RemoveProductTaxonsTable < ActiveRecord::Migration[7.0]
  def change
    drop_table :spree_products_taxons
  end
end
