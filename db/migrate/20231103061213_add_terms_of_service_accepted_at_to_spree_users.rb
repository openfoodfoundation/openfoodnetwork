class AddTermsOfServiceAcceptedAtToSpreeUsers < ActiveRecord::Migration[7.0]
  def up
    add_column :spree_users, :terms_of_service_accepted_at, :datetime

    if Spree::Config.enterprises_require_tos == true
      # There isn't really a way to know which user have access to admin pages, so we update
      # everyone. It's technically wrong to say shoppers have accepted ToS, but they will be
      # required to accept the terms if they sign up for an enterprise.
      Spree::User.update_all(terms_of_service_accepted_at: Time.zone.now)
    end
  end

  def down
   remove_column :spree_users, :terms_of_service_accepted_at
  end
end
