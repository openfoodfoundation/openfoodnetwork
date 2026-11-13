# frozen_string_literal: true

class UserPasswordsController < Spree::UserPasswordsController
  layout 'darkswarm'

  def create
    return render_unconfirmed_response if user_unconfirmed?

    self.resource = resource_class.send_reset_password_instructions(raw_params[resource_name])

    # Don't say when the email isn't registered, so the form can't be used to find out which
    # email addresses are.
    message = resource.errors.empty? ? t(:password_reset_sent) : t(:password_reset_requested)

    render turbo_stream: turbo_stream.update(
      'forgot-feedback',
      partial: 'layouts/alert',
      locals: { type: :success, message:, tab: 'forgot',
                unconfirmed: false, email: params.dig(:spree_user, :email) }
    )
  end

  private

  def render_unconfirmed_response
    message, type, unconfirmed, tab = [t(:email_unconfirmed), :alert, true, 'forgot']

    render turbo_stream: turbo_stream.update(
      'forgot-feedback',
      partial: 'layouts/alert',
      locals: { type:, message:, tab:,
                unconfirmed:, email: params.dig(:spree_user, :email) }
    ), status: :unprocessable_entity
  end

  def user_unconfirmed?
    user = Spree::User.find_by(email: params.dig(:spree_user, :email))
    user && !user.confirmed?
  end
end
