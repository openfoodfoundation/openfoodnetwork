class DropPrototypesTables < ActiveRecord::Migration[4.2]
  def up
    drop_table :spree_option_types_prototypes
    drop_table :spree_properties_prototypes
    drop_table :spree_prototypes
  end

  def down
    create_table :spree_prototypes do |t|
      t.string   :name
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end

    create_table :spree_option_types_prototypes, id: false do |t|
      t.integer :prototype_id
      t.integer :option_type_id
    end

    create_table :spree_properties_prototypes, id: false do |t|
      t.integer :prototype_id
      t.integer :property_id
    end
  end
end
