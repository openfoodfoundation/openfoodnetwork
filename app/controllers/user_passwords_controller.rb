# frozen_string_literal: true

class UserPasswordsController < Spree::UserPasswordsController
  layout 'darkswarm'

  # Respond the same way whether or not the email belongs to an account, so the form can't be
  # used to find out which email addresses are registered.
  def create
    email = raw_params.dig(resource_name, :email)
    user = resource_class.find_for_authentication(email:) if email.present?

    if user && !user.confirmed?
      # They can't reset their password before confirming their email, send the confirmation
      # email again instead.
      user.resend_confirmation_instructions
    elsif user
      user.send_reset_password_instructions
    end

    render turbo_stream: turbo_stream.update(
      'forgot-feedback',
      partial: 'layouts/alert',
      locals: { type: :success, message: t(:password_reset_requested) }
    )
  end
end
