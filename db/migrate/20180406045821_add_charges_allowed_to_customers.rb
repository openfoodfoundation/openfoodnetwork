class AddChargesAllowedToCustomers < ActiveRecord::Migration
  def change
    add_column :customers, :allow_charges, :boolean, default: false, null: false
  end
end
