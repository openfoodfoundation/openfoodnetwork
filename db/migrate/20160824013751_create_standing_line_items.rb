class CreateStandingLineItems < ActiveRecord::Migration
  def change
    create_table :standing_line_items do |t|
      t.references :standing_order, null: false
      t.references :variant, null: false
      t.integer :quantity, null: false
      t.timestamps
    end

    add_index :standing_line_items, :standing_order_id
    add_index :standing_line_items, :variant_id

    add_foreign_key :standing_line_items, :standing_orders, name: 'oc_standing_line_items_standing_order_id_fk'
    add_foreign_key :standing_line_items, :spree_variants, name: 'oc_standing_line_items_variant_id_fk', column: :variant_id
  end
end
