class AddEnterpriseLimitToSpreeUsers < ActiveRecord::Migration
  def up
    add_column :spree_users, :enterprise_limit, :integer, default: 1, null: false

    Spree::User.all.each do |u|
      e_count = u.owned_enterprises.length
      if u.admin? || e_count > 1
        e_limit = 100
        e_limit = 1000 if u.admin?
        u.update_column :enterprise_limit, e_limit
      end
    end
  end

  def down
    remove_column :spree_users, :enterprise_limit
  end
end
