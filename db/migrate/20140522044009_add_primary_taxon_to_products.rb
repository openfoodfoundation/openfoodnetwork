class AddPrimaryTaxonToProducts < ActiveRecord::Migration
  def up
    add_column :spree_products, :primary_taxon_id, :integer

    add_index :spree_products, :primary_taxon_id
    add_foreign_key :spree_products, :spree_taxons, column: :primary_taxon_id

    Spree::Product.all.each do |p|
      p.update_column :primary_taxon_id, (p.taxons.first || Spree::Taxon.first)
    end

    change_column :spree_products, :primary_taxon_id, :integer, null: false
  end

  def down
    remove_column :spree_products, :primary_taxon_id
  end
end
