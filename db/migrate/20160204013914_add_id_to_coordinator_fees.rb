class AddIdToCoordinatorFees < ActiveRecord::Migration
  def change
    add_column :coordinator_fees, :id, :primary_key
  end
end
