class AddPrimaryTaxonToProducts < ActiveRecord::Migration
  def change
    add_column :spree_products, :primary_taxon_id, :integer
  end
end
