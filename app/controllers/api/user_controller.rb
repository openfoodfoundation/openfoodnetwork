# frozen_string_literal: true

module Api
  class UserController < Api::BaseController
    skip_authorization_check only: [:index]

    def index
      render json: current_api_user
    end
  end
end
