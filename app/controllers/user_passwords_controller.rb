class UserPasswordsController < Spree::UserPasswordsController
  layout 'darkswarm'

  before_filter :set_admin_redirect, only: :edit

  def create
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
          render json: resource.errors, status: :unauthorized
        end
      end
    end
  end

  private

  def set_admin_redirect
    session["spree_user_return_to"] = params[:return_to] if params[:return_to]
  end
end
