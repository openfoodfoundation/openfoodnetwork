class CreateCustomers < ActiveRecord::Migration
  def change
    create_table :customers do |t|
      t.string :email
      t.references :enterprises
      t.text :customer_code

      t.timestamps
    end
    add_index :customers, :enterprises_id
  end
end
