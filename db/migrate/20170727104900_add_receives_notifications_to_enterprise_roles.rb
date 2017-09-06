class AddReceivesNotificationsToEnterpriseRoles < ActiveRecord::Migration
  def change
    add_column :enterprise_roles, :receives_notifications, :boolean, default: false
  end
end
