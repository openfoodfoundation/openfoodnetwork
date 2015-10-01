class CreateBillItems < ActiveRecord::Migration
  def change
    create_table :bill_items do |t|
      t.references :enterprise, nil: false
      t.references :owner, nil: false
      t.datetime :begins_at, default: nil
      t.datetime :ends_at, default: nil
      t.string :sells, default: nil
      t.boolean :trial, default: false
      t.decimal :turnover, default: 0.0
      t.foreign_key :enterprises
      t.foreign_key :spree_users, column: :owner_id
    end
  end
end
