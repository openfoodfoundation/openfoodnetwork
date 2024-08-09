class DropSpreeTaxonomiesTable < ActiveRecord::Migration[7.0]
  def change
    # Remove columns
    remove_column :spree_taxons, :lft, :integer
    remove_column :spree_taxons, :rgt, :integer

    # Remove references
    remove_reference :spree_taxons, :parent, index: true, foreign_key: { to_table: :spree_taxons }
    remove_reference :spree_taxons, :taxonomy, index: true, foreign_key: { to_table: :spree_taxonomies }

    # Drop table
    drop_table :spree_taxonomies, id: :serial, force: :cascade do |t|
      t.string "name", limit: 255, null: false
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
      t.integer "position", default: 0
    end
  end
end
