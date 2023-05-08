class AddTypeToVouchers < ActiveRecord::Migration[7.0]
  def change
    add_column :vouchers, :voucher_type, :string, limit: 255
  end
end
