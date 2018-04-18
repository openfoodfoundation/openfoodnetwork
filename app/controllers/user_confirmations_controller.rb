class UserConfirmationsController < DeviseController
  include Spree::Core::ControllerHelpers::Auth # Needed for access to current_ability, so we can authorize! actions

  # GET /resource/confirmation/new
  def new
    build_resource({})
  end

  # POST /resource/confirmation
  def create
    set_return_url if params.key? :return_url
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

  def set_return_url
    session[:confirmation_return_url] = params[:return_url]
  end

  def after_confirmation_path_for(resource)
    result =
      if resource.errors.empty?
        'confirmed'
      else
        'not_confirmed'
      end

    if resource.reset_password_token.present?
      return spree.edit_spree_user_password_path(reset_password_token: resource.reset_password_token)
    end

    path = (session[:confirmation_return_url] || login_path).to_s
    path += path.include?('?') ? '&' : '?'
    path + "validation=#{result}"
  end
end
