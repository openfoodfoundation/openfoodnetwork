class RemoveEmailFromEnterprises < ActiveRecord::Migration
  class Enterprise < ActiveRecord::Base; end
  class Spree::User < ActiveRecord::Base; end

  class EnterpriseRole < ActiveRecord::Base
    belongs_to :user, class_name: 'Spree::User'
    belongs_to :enterprise, class_name: 'Enterprise'
  end

  def up
    Enterprise.reset_column_information
    Spree::User.reset_column_information
    EnterpriseRole.reset_column_information

    Enterprise.select([:id, :email, :owner_id]).each do |enterprise|
      update_enterprise_contact enterprise
    end

    remove_column :enterprises, :email
    rename_column :enterprises, :contact, :contact_name
  end

  def down
    Enterprise.reset_column_information
    Spree::User.reset_column_information
    EnterpriseRole.reset_column_information

    add_column :enterprises, :email, :string
    rename_column :enterprises, :contact_name, :contact

    Enterprise.select(:id).each do |e|
      manager = EnterpriseRole.find_by_enterprise_id_and_receives_notifications(e.id, true)
      user = Spree::User.find(manager.user_id)
      e.update_attribute :email, user.email
    end
  end

  def update_enterprise_contact(enterprise)
    contact_user = contact_or_owner(enterprise)

    role = EnterpriseRole.find_or_initialize_by_user_id_and_enterprise_id(contact_user.id, enterprise.id)
    role.update_attribute :receives_notifications, true
  end

  def contact_or_owner(enterprise)
    Spree::User.find_by_email(enterprise.email) || Spree::User.find(enterprise.owner_id)
  end
end
