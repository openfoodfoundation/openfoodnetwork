class AddTermsOfServiceAcceptedAtToSpreeUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :spree_users, :terms_of_service_accepted_at, :datetime
  end
end
