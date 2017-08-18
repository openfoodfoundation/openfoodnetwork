class UserConfirmationsController < DeviseController
  include Spree::Core::ControllerHelpers::Auth # Needed for access to current_ability, so we can authorize! actions

  # GET /resource/confirmation/new
  def new
    build_resource({})
  end

  # POST /resource/confirmation
  def create
    self.resource = resource_class.send_confirmation_instructions(resource_params)

    if is_navigational_format?
      if successfully_sent?(resource)
        set_flash_message(:success, :confirmation_sent)
      else
        set_flash_message(:error, :confirmation_not_sent)
      end
    end

    respond_with_navigational(resource){ redirect_to login_path }
  end

  # GET /resource/confirmation?confirmation_token=abcdef
  def show
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])

    if is_navigational_format?
      if resource.errors.empty?
        set_flash_message(:success, :confirmed)
      else
        set_flash_message(:error, :not_confirmed)
      end
    end

    respond_with_navigational(resource){ redirect_to login_path }
  end
end
