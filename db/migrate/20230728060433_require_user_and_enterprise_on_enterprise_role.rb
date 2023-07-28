class RequireUserAndEnterpriseOnEnterpriseRole < ActiveRecord::Migration[7.0]
  def change
    change_column_null :enterprise_roles, :user_id, false
    change_column_null :enterprise_roles, :enterprise_id, false
  end
end
