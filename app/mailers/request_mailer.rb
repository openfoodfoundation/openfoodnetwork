# frozen_string_literal: true

class RequestMailer < ApplicationMailer
  def request_email(user, enterprise, token)
    @user = user
    @enterprise = enterprise
    @token = token
    return if @user.email.blank?

    mail(to: ENV['FRUITS_EMAIL'], from: @user.email,
         subject: 'Enterprise Access Request')
  end

  def approval_notification(user_email, message)
    @message = message
    return if user_email.blank?

    mail(to: user_email, from: ENV['FRUITS_EMAIL'],
         subject: 'Enterprise Approval Notification')
  end
end
