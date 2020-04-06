# This migration comes from spree (originally 20131127001002)
class AddPositionToClassifications < ActiveRecord::Migration
  def change
    add_column :spree_products_taxons, :position, :integer
  end
end
