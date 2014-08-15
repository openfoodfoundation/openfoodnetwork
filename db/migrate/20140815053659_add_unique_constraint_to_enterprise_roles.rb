class AddUniqueConstraintToEnterpriseRoles < ActiveRecord::Migration
  def change
    add_index :enterprise_roles, [:user_id, :enterprise_id], unique: true
  end
end
