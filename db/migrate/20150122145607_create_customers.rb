class CreateCustomers < ActiveRecord::Migration
  def change
    create_table :customers do |t|
      t.string :email, null: false
      t.references :enterprise, null: false
      t.string :code, null: false
      t.references :user

      t.timestamps
    end
    add_index :customers, [:enterprise_id, :code], unique: true
    add_index :customers, :email
    add_index :customers, :user_id

    add_foreign_key :customers, :enterprises, column: :enterprise_id
    add_foreign_key :customers, :spree_users, column: :user_id
  end
end
