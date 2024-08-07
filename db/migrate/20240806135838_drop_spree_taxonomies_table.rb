class DropSpreeTaxonomiesTable < ActiveRecord::Migration[7.0]
  def change
    # Remove columns
    remove_column :spree_taxons, :lft
    remove_column :spree_taxons, :rgt

    # Remove references
    remove_reference :spree_taxons, :parent, index: true, foriegn_key: true
    remove_reference :spree_taxons, :taxonomy, index: true, foriegn_key: true

    # Drop table
    drop_table :spree_taxonomies
  end
end
