class RequireParentAndChildOnEnterpriseRelationship < ActiveRecord::Migration[7.0]
  def change
    change_column_null :enterprise_relationships, :parent_id, false
    change_column_null :enterprise_relationships, :child_id, false
  end
end
