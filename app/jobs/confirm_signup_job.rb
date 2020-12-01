# frozen_string_literal: true

class ConfirmSignupJob < ActiveJob::Base
  def perform(user_id)
    user = Spree::User.find user_id
    Spree::UserMailer.signup_confirmation(user).deliver
  end
end
