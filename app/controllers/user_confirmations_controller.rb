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

    respond_with_navigational(resource){ redirect_to after_confirmation_path_for(resource) }
  end

  protected

  def after_confirmation_path_for(_resource)
    result =
      if resource.errors.empty?
        'confirmed'
      else
        'not_confirmed'
      end

    url = session[:confirmation_return_url] || login_path
    url + "?confirmation=#{result}"
  end
end
