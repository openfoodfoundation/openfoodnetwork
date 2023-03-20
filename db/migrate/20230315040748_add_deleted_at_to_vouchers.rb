class AddDeletedAtToVouchers < ActiveRecord::Migration[6.1]
  def change
    add_column :vouchers, :deleted_at, :datetime
    add_index :vouchers, :deleted_at
  end
end
