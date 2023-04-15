class AddCreatedManuallyFlagToCustomer < ActiveRecord::Migration[7.0]
  def change
    add_column :customers, :created_manually, :boolean, default: false
  end
end
