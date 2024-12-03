class AddExternalVoucherIdExternalVoucherSetIdVoucherTypeToVouchers < ActiveRecord::Migration[7.0]
  def change
    add_column :vouchers, :external_voucher_id, :uuid
    add_column :vouchers, :external_voucher_set_id, :uuid
    add_column :vouchers, :voucher_type, :string
  end
end
