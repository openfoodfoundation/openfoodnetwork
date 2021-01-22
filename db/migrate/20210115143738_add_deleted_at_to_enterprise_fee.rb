class AddDeletedAtToEnterpriseFee < ActiveRecord::Migration
  def change
    add_column :enterprise_fees, :deleted_at, :datetime
  end
end
