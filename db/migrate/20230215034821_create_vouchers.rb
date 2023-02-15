class CreateVouchers < ActiveRecord::Migration[6.1]
  def change
    create_table :vouchers do |t|
      t.string :code, null: false, limit: 255
      t.datetime :expiry_date

      t.timestamps
    end
    add_reference :vouchers, :enterprise, foreign_key: true
    add_index :vouchers, [:code, :enterprise_id], unique: true
  end
end
