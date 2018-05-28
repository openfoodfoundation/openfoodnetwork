class UserPasswordsController < Spree::UserPasswordsController
  layout 'darkswarm'

  before_filter :set_admin_redirect, only: :edit

  def create
    render_unconfirmed_response && return if user_unconfirmed?

    self.resource = resource_class.send_reset_password_instructions(params[resource_name])

    if resource.errors.empty?
      set_flash_message(:success, :send_instructions) if is_navigational_format?
      respond_with resource, :location => spree.login_path
    else
      respond_to do |format|
        format.html do
          respond_with_navigational(resource) { render :new }
        end
        format.js do
          render json: { error: t('email_not_found') }, status: :not_found
        end
      end
    end
  end

  private

  def set_admin_redirect
    session["spree_user_return_to"] = params[:return_to] if params[:return_to]
  end

  def render_unconfirmed_response
    render json: { error: t('email_unconfirmed') }, status: :unauthorized
  end

  def user_unconfirmed?
    user = Spree::User.find_by_email(params[:spree_user][:email])
    user && !user.confirmed?
  end
end
