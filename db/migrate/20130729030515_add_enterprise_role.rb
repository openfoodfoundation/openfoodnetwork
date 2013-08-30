class AddEnterpriseRole < ActiveRecord::Migration
  def change
    create_table :enterprise_roles do |t|
      t.references :user, index: true
      t.references :enterprise, index: true
    end
  end
end
