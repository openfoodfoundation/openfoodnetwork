require 'open_food_network/spree_api_key_loader'

class RegistrationController < BaseController
  include OpenFoodNetwork::SpreeApiKeyLoader
  before_filter :load_spree_api_key, only: [:index]
  before_filter :check_user, except: :authenticate
  layout 'registration'

  def index
    @enterprise_attributes = { sells: 'none' }
  end

  private

  def check_user
    if spree_current_user.nil?
      redirect_to registration_auth_path(anchor: "signup?after_login=#{request.env['PATH_INFO']}")
    elsif !spree_current_user.can_own_more_enterprises?
      render :limit_reached
    end
  end
end
