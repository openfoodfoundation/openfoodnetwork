class AddPrimaryTaxonToProducts < ActiveRecord::Migration
  def change
    add_column :spree_products, :primary_taxon_id, :integer
<<<<<<< HEAD
<<<<<<< HEAD
    add_index :spree_products, :primary_taxon_id
    add_foreign_key :spree_products, :spree_taxons, column: :primary_taxon_id
=======
>>>>>>> fd1e7eb... Adding primary taxon field to product
=======
    add_index :spree_products, :primary_taxon_id
    add_foreign_key :spree_products, :spree_taxons, column: :primary_taxon_id
>>>>>>> 110a6f2... Adding primary taxon to admin forms
  end
end
