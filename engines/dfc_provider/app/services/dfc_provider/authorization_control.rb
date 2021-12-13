# frozen_string_literal: true

# Service used to authorize the user on DCF Provider API
# It controls an OICD Access token and an enterprise.
module DfcProvider
  class AuthorizationControl
    def initialize(access_token)
      @access_token = access_token
    end

    def safe_process
      process
    rescue JWT::VerificationError, JWT::ExpiredSignature, JWT::ImmatureSignature => e
      # To help development debugging
      raise e if Rails.env.development?

      nil
    end

    def process
      decode_token
      control_payload
      find_ofn_user
    end

    private

    def decode_token
      data = JWT.decode(
        @access_token,
        nil,
        true,
        { algorithms: ['RS256'], jwks: jwks_hash }
      )

      @header = data.last
      @payload = data.first
    end

    def find_ofn_user
      Spree::User.where(provider: 'openid_connect', uid: @payload['email']).first
    end

    def control_payload
      raise 'Email Not Found' if @payload['email'].blank?
    end

    def jwks_uri
      Devise.omniauth_configs[:openid_connect].options[:client_options][:jwks_uri]
    end

    def jwks_hash
      jwks_raw = Net::HTTP.get URI(jwks_uri)

      JSON.parse(jwks_raw)
    end
  end
end
