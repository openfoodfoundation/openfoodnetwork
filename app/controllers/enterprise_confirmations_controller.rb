class EnterpriseConfirmationsController < DeviseController
  include Spree::Core::ControllerHelpers::Auth # Needed for access to current_ability, so we can authorize! actions

  # GET /resource/confirmation/new
  def new
    build_resource({})
  end

  # POST /resource/confirmation
  def create
    self.resource = resource_class.find_by_unconfirmed_email_with_errors(resource_params)
    authorize! :resend_confirmation, resource

    self.resource = resource_class.send_confirmation_instructions(resource_params)

    if successfully_sent?(resource)
      set_flash_message(:success, :confirmation_sent) if is_navigational_format?
    else
      set_flash_message(:error, :confirmation_not_sent) if is_navigational_format?
    end

    respond_with_navigational(resource){ redirect_to spree.admin_path }
  end

  # GET /resource/confirmation?confirmation_token=abcdef
  def show
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])

    if resource.errors.empty?
      set_flash_message(:success, :confirmed) if is_navigational_format?
    else
      set_flash_message(:error, :not_confirmed) if is_navigational_format?
    end

    respond_with_navigational(resource){ redirect_to redirect_path(resource) }
  end

  private

  def new_user_reset_path(resource)
    password = Devise.friendly_token.first(8)
    user = Spree::User.create(email: resource.email, password: password, password_confirmation: password)
    user.send_reset_password_instructions_without_delay
    resource.users << user
    spree.edit_spree_user_password_path(user, :reset_password_token => user.reset_password_token, return_to: spree.admin_path)
  end

  def redirect_path(resource)
    if resource.persisted? && !Spree::User.exists?(email: resource.email)
      new_user_reset_path(resource)
    else
      spree.admin_path
    end
  end
end
