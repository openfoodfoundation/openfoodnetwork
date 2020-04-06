# This migration comes from spree (originally 20130619012236)
class AddUpdatedAtToSpreeStates < ActiveRecord::Migration
  def up
    add_column :spree_states, :updated_at, :datetime
  end

  def down
    remove_column :spree_states, :updated_at
  end
end
