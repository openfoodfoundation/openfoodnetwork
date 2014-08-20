class RegistrationController < BaseController
  layout 'registration'

  def index
    if spree_current_user.nil?
      redirect_to registration_auth_path(anchor: "login?after_login=/register")
    end
  end
end
