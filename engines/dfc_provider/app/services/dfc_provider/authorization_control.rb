# frozen_string_literal: true

# Service used to authorize the user on DCF Provider API
# It controls an OICD Access token and an enterprise.
module DfcProvider
  class AuthorizationControl
    def initialize(request)
      @request = request
    end

    def process
      oidc_user || ofn_user
    end

    private

    def oidc_user
      return unless access_token

      decode_token
      find_ofn_user
    end

    def ofn_user
      @request.env['warden'].user
    end

    def decode_token
      data = JWT.decode(
        access_token,
        nil,
        false
      )

      @header = data.last
      @payload = data.first
    end

    def access_token
      @request.headers['Authorization'].to_s.split(' ').last
    end

    def find_ofn_user
      Spree::User.where(email: @payload['email']).first
    end
  end
end
