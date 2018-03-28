class ChangeDefaultValueOfSpreeUsersEnterpriseLimit < ActiveRecord::Migration
  def up
    change_column :spree_users, :enterprise_limit, :integer, default: 5
  end

  def down
    change_column :spree_users, :enterprise_limit, :integer, default: 1
  end
end
