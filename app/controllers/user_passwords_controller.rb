# frozen_string_literal: true

class UserPasswordsController < Spree::UserPasswordsController
  layout 'darkswarm'

  def create
    return render_unconfirmed_response if user_unconfirmed?

    self.resource = resource_class.send_reset_password_instructions(raw_params[resource_name])

    if resource.errors.empty?
      @message = t(:password_reset_sent)
      @type = :success
      respond_to do |format|
        format.html { head :ok }
        format.turbo_stream { render :create }
      end
    else
      @type = :alert
      @message = t(:email_not_found)
      respond_to do |format|
        format.html { head :not_found }
        format.turbo_stream { render :create, status: :not_found }
      end
    end
  end

  private

  def render_unconfirmed_response
    @type = :alert
    @message = t(:email_unconfirmed)
    @unconfirmed = true
    @tab = 'forgot'
    respond_to do |format|
      format.html { head :unprocessable_entity }
      format.turbo_stream { render :create, status: :unprocessable_entity }
    end
  end

  def user_unconfirmed?
    @user = Spree::User.find_by(email: params.dig(:spree_user, :email))
    @user && !@user.confirmed?
  end
end
