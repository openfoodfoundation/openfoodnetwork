class AddOwnerToEnterpriseGroups < ActiveRecord::Migration
  def change
    add_column :enterprise_groups, :owner_id, :integer
    add_foreign_key :enterprise_groups, :spree_users, name: "enterprise_groups_owner_id_fk", column: "owner_id"
  end
end
