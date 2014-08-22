require 'open_food_network/spree_api_key_loader'

class RegistrationController < BaseController
  include OpenFoodNetwork::SpreeApiKeyLoader
  before_filter :load_spree_api_key, :only => :index
  layout 'registration'

  def index
    if spree_current_user.nil?
      redirect_to registration_auth_path(anchor: "signup?after_login=/register")
    end
  end
end
