class UpdateIndexAndRemoveVoucherTypeFromVoucher < ActiveRecord::Migration[7.0]
  def change
    remove_column :vouchers, :voucher_type
    remove_index :vouchers, [:code, :enterprise_id], unique: true

    add_index :vouchers, [:code, :enterprise_id]
    add_index :vouchers, [:code, :enterprise_id, :external_voucher_id], name: "index_vouchers_on_code_and_enterprise_id_and_ext_voucher_id"
  end
end
