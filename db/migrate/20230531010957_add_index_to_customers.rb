class AddIndexToCustomers < ActiveRecord::Migration[7.0]
  def change
    add_index :customers, :created_manually
  end
end
