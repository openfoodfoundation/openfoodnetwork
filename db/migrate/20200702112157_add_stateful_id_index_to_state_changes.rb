class AddStatefulIdIndexToStateChanges < ActiveRecord::Migration
  def change
    add_index :spree_state_changes, :stateful_id
  end
end
