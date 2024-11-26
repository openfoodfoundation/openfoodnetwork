# frozen_string_literal: true

class UserPasswordsController < Spree::UserPasswordsController
  layout 'darkswarm'

  def create
    return render_unconfirmed_response if user_unconfirmed?

    self.resource = resource_class.send_reset_password_instructions(raw_params[resource_name])

    if resource.errors.empty?
      @message, @type = [t(:password_reset_sent), :success]
      render :create
    else
      @message, @type = [t(:email_not_found), :alert]
      render :create, status: :not_found
    end
  end

  private

  def render_unconfirmed_response
    @message, @type, @unconfirmed, @tab = [t(:email_unconfirmed), :alert, true, 'forgot']

    render :create, status: :unprocessable_entity
  end

  def user_unconfirmed?
    user = Spree::User.find_by(email: params.dig(:spree_user, :email))
    user && !user.confirmed?
  end
end
