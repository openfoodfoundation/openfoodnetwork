class RequireEnterpriseRelationshipOnEnterpriseRelationshipPermission < ActiveRecord::Migration[7.0]
  def change
    change_column_null :enterprise_relationship_permissions, :enterprise_relationship_id, false
  end
end
