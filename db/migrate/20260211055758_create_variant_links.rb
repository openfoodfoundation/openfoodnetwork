class CreateVariantLinks < ActiveRecord::Migration[7.1]
  def change
    # Create a join table to join two variants. One is the source of the other.
    # Primary key index ensures uniqueness and assists querying. linked_variant_id is the most
    # likely subject and so is first in the index.
    # An additional index for source_variant is also included because it may be helpful
    # (https://stackoverflow.com/questions/10790518/best-sql-indexes-for-join-table).
    create_table :variant_links, primary_key: [:linked_variant_id, :source_variant_id] do |t|
      t.integer :source_variant_id, null: false, index: true
      t.integer :linked_variant_id, null: false

      t.timestamps
    end
    add_foreign_key :variant_links, :spree_variants, column: :source_variant_id
    add_foreign_key :variant_links, :spree_variants, column: :linked_variant_id
  end
end
