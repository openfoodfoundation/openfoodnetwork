class AddWebConactToEnterpriseGroups < ActiveRecord::Migration
  def change
    add_column :enterprise_groups, :email, :string
    add_column :enterprise_groups, :website, :string
    add_column :enterprise_groups, :facebook, :string
    add_column :enterprise_groups, :instagram, :string 
    add_column :enterprise_groups, :linkedin, :string
    add_column :enterprise_groups, :twitter, :string
  end
end
