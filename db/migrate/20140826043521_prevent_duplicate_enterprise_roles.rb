class PreventDuplicateEnterpriseRoles < ActiveRecord::Migration
  def change
    add_index :enterprise_roles, [:enterprise_id, :user_id], unique: true
  end
end
