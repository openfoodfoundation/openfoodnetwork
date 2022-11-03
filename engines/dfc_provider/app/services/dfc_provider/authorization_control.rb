# frozen_string_literal: true

# Service used to authorize the user on DCF Provider API
# It controls an OICD Access token and an enterprise.
module DfcProvider
  class AuthorizationControl
    def initialize(request)
      @request = request
    end

    def user
      oidc_user || ofn_user
    end

    private

    def oidc_user
      find_ofn_user(decode_token) if access_token
    end

    def ofn_user
      @request.env['warden'].user
    end

    def decode_token
      JWT.decode(access_token, nil, false).first
    end

    def access_token
      @request.headers['Authorization'].to_s.split(' ').last
    end

    def find_ofn_user(payload)
      Spree::User.find_by(email: payload["email"])
    end
  end
end
