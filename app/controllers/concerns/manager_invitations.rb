# frozen_string_literal: true

module ManagerInvitations
  extend ActiveSupport::Concern

  def create_new_manager(email, enterprise)
    password = Devise.friendly_token
    new_user = Spree::User.create(email: email, unconfirmed_email: email, password: password)
    new_user.reset_password_token = Devise.friendly_token
    # Same time as used in Devise's lib/devise/models/recoverable.rb.
    new_user.reset_password_sent_at = Time.now.utc
    if new_user.save
      enterprise.users << new_user
      EnterpriseMailer.manager_invitation(enterprise, new_user).deliver_later
    end

    new_user
  end
end
