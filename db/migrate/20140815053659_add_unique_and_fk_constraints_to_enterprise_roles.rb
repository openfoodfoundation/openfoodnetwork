class AddUniqueAndFkConstraintsToEnterpriseRoles < ActiveRecord::Migration
  def change
    add_index :enterprise_roles, [:user_id, :enterprise_id], unique: true

    add_foreign_key :enterprise_roles, :spree_users, column: :user_id
    add_foreign_key :enterprise_roles, :enterprises, column: :enterprise_id
  end
end
