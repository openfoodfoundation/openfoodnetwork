class CreateVariantOverrides < ActiveRecord::Migration
  def change
    create_table :variant_overrides do |t|
      t.references :variant
      t.references :hub
      t.decimal :price, precision: 8, scale: 2
      t.integer :count_on_hand
    end

    add_foreign_key :variant_overrides, :spree_variants, column: :variant_id
    add_foreign_key :variant_overrides, :enterprises, column: :hub_id

    add_index :variant_overrides, [:variant_id, :hub_id]
  end
end
