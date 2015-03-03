class AddOwnerIndexToEnterpriseGroups < ActiveRecord::Migration
  def change
    add_index :enterprise_groups, :owner_id
  end
end
