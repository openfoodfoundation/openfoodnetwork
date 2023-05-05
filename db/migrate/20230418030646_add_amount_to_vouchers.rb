class AddAmountToVouchers < ActiveRecord::Migration[7.0]
  def change
    add_column :vouchers, :amount, :decimal, precision: 10, scale: 2, null: false, default: 0
  end
end
