class AddStatefulIdIndexToStateChanges < ActiveRecord::Migration[4.2]
  def change
    add_index :spree_state_changes, :stateful_id
  end
end
