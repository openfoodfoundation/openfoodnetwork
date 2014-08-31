class CreateProducerProperties < ActiveRecord::Migration
  def change
    create_table :producer_properties do |t|
      t.string :value
      t.references :producer
      t.references :property
      t.integer :position
      t.timestamps
    end

    add_index :producer_properties, :producer_id
    add_index :producer_properties, :property_id
    add_index :producer_properties, :position

    add_foreign_key :producer_properties, :enterprises, column: :producer_id
    add_foreign_key :producer_properties, :spree_properties, column: :property_id
  end
end
