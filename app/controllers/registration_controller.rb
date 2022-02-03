# frozen_string_literal: true

require 'open_food_network/spree_api_key_loader'

class RegistrationController < BaseController
  include OpenFoodNetwork::SpreeApiKeyLoader

  layout 'registration'
  helper 'map'

  before_action :load_spree_api_key, only: [:index]
  before_action :check_user, except: :authenticate

  def index
    @enterprise_attributes = { sells: 'none' }
  end

  private

  def check_user
    if spree_current_user.nil?
      redirect_to registration_auth_path(anchor: "/signup", after_login: request.original_fullpath)
    elsif !spree_current_user.can_own_more_enterprises?
      render :limit_reached
    end
  end
end
