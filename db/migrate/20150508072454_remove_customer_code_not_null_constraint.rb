class RemoveCustomerCodeNotNullConstraint < ActiveRecord::Migration
  def up
    change_column :customers, :code, :string, null: true
  end

  def down
    change_column :customers, :code, :string, null: false
  end
end
