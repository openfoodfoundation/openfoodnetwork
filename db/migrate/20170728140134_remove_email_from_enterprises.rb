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
      contact_user = Spree::User.find_by_email enterprise.email
      unless contact_user
        password = Devise.friendly_token.first(8)
        contact_user = Spree::User.create(email: enterprise.email, password: password, password_confirmation: password)
        contact_user.send_reset_password_instructions if contact_user.persisted?
      end

      unless contact_user.persisted?
        contact_user = Spree::User.find enterprise.owner_id
      end

      manager = EnterpriseRole.find_or_initialize_by_user_id_and_enterprise_id(contact_user.id, enterprise.id)
      manager.update_attribute :receives_notifications, true
    end

    remove_columns :enterprises, :email, :contact
  end

  def down
    Enterprise.reset_column_information
    Spree::User.reset_column_information
    EnterpriseRole.reset_column_information

    add_column :enterprises, :email, :string
    add_column :enterprises, :contact, :string

    Enterprise.select(:id).each do |e|
      manager = EnterpriseRole.find_by_enterprise_id_and_receives_notifications(e.id, true)
      user = Spree::User.find(manager.user_id)
      e.update_attribute :email, user.email
    end
  end
end
