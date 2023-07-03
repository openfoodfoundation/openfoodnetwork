class AddTypeToVouchers < ActiveRecord::Migration[7.0]
  def up
    # It will set all the vouchers till now to Vouchers::FlatRate
    add_column :vouchers, :type, :string, limit: 255, null: false, default: "Vouchers::FlatRate"
  end

  def down
    remove_column :vouchers, :type
  end
end
