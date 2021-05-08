class RemoveFieldNameFromExchange < ActiveRecord::Migration[4.2]
  def up
    remove_column :exchanges, :payment_enterprise_id
  end

  def down
    add_column :exchanges, :payment_enterprise_id, :integer
  end
end
