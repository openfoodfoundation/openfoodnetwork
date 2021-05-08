class AddDeletedAtToEnterpriseFee < ActiveRecord::Migration[4.2]
  def change
    add_column :enterprise_fees, :deleted_at, :datetime
  end
end
