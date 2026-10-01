# frozen_string_literal: true

module Oauth
  # Tells an external application which OFN user granted it an access token.
  class UserinfoController < ActionController::API
    before_action -> { doorkeeper_authorize! :profile }

    def show
      user = Spree::User.find(doorkeeper_token.resource_owner_id)

      render json: { sub: user.id.to_s, email: user.email }
    end
  end
end
