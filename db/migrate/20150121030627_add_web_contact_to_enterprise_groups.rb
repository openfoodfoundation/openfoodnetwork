class AddWebContactToEnterpriseGroups < ActiveRecord::Migration
  def change
    add_column :enterprise_groups, :email, :string, null: false, default: ''
    add_column :enterprise_groups, :website, :string, null: false, default: ''
    add_column :enterprise_groups, :facebook, :string, null: false, default: ''
    add_column :enterprise_groups, :instagram, :string, null: false, default: ''
    add_column :enterprise_groups, :linkedin, :string, null: false, default: ''
    add_column :enterprise_groups, :twitter, :string, null: false, default: ''
  end
end
