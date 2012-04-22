class AddStateToDistributor < ActiveRecord::Migration
  def change
    add_column :distributors, :state_id, :integer
  end
end
