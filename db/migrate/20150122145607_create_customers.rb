class CreateCustomers < ActiveRecord::Migration
  def change
    create_table :customers do |t|
      t.string :email
      t.references :enterprise
      t.string :code

      t.timestamps
    end
    add_index :customers, [:enterprise_id, :code], unique: true
    add_index :customers, :email
  end
end
