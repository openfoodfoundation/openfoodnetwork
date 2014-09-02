class CreateEnterpriseRelationshipPermissions < ActiveRecord::Migration
  def change
    create_table :enterprise_relationship_permissions do |t|
      t.references :enterprise_relationship
      t.string :name, null: false
    end

    add_index :enterprise_relationship_permissions, :enterprise_relationship_id, name: 'index_erp_on_erid'
    add_foreign_key :enterprise_relationship_permissions, :enterprise_relationships, name: 'erp_enterprise_relationship_id_fk'
  end
end
