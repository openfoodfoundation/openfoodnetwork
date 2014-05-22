class AddPrimaryTaxonToProducts < ActiveRecord::Migration
  def change
    add_column :spree_products, :primary_taxon_id, :integer
    add_index :spree_products, :primary_taxon_id
    add_foreign_key :spree_products, :spree_taxons, column: :primary_taxon_id
  end
end
