class AddTermsOfServiceAcceptedAtToSpreeUsers < ActiveRecord::Migration[7.0]
  def up
    add_column :spree_users, :terms_of_service_accepted_at, :datetime

    if Spree::Config.enterprises_require_tos == true
      Spree::User.update_all(terms_of_service_accepted_at: Time.zone.now)
    end
  end

  def down
   remove_column :spree_users, :terms_of_service_accepted_at
  end
end
