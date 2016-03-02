class CreateInventoryItems < ActiveRecord::Migration
  def change
    create_table :inventory_items do |t|
      t.references :enterprise, null: false, index: true
      t.references :variant, null: false, index: true
      t.boolean :visible, default: true, null: false

      t.timestamps
    end

    add_index "inventory_items", [:enterprise_id, :variant_id], unique: true
  end
end
