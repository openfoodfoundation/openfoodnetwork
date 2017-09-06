class RemoveEmailFromEnterprises < ActiveRecord::Migration
  def up
    Enterprise.select([:id, :email]).each do |e|
      contact_user = Spree::User.find_by_email e.email
      manager = EnterpriseRole.find_or_initialize_by_user_id_and_enterprise_id(contact_user.id, e.id)
      manager.update_attribute :receives_notifications, true
    end

    remove_columns :enterprises, :email, :contact
  end

  def down
    add_column :enterprises, :email, :string
    add_column :enterprises, :contact, :string

    Enterprise.select(:id).each do |e|
      contact_user = EnterpriseRole.receives_notifications_for(e.id)
      e.update_attribute :email, contact_user.email
    end
  end
end