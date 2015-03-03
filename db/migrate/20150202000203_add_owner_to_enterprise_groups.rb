class AddOwnerToEnterpriseGroups < ActiveRecord::Migration
  def change
    add_column :enterprise_groups, :owner_id, :integer
    add_foreign_key :enterprise_groups, :spree_users, column: "owner_id"
  end
end
