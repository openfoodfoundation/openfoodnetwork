class CreateEnterpriseRelationships < ActiveRecord::Migration
  def change
    create_table :enterprise_relationships do |t|
      t.integer :parent_id
      t.integer :child_id
    end

    add_index :enterprise_relationships, :parent_id
    add_index :enterprise_relationships, :child_id

    add_index :enterprise_relationships, [:parent_id, :child_id], unique: true

    add_foreign_key :enterprise_relationships, :enterprises, column: :parent_id
    add_foreign_key :enterprise_relationships, :enterprises, column: :child_id
  end
end
