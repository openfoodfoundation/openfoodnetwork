# frozen_string_literal: true

class RequestMailer < ApplicationMailer
  def request_email(user, enterprise, token)
    @user = user
    @enterprise = enterprise
    @token = token
    return if @user.email.blank?

    mail(to: 'fruits@labelleorange.es', from: @user.email,
         subject: 'Enterprise Access Request')
  end

  def approval_notification(user_email, message)
    @message = message
    return if user_email.blank?

    mail(to: user_email, from: 'fruits@labelleorange.es',
         subject: 'Enterprise Approval Notification')
  end
end
