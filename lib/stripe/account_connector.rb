# frozen_string_literal: true

# Encapsulation of logic used to handle the response from Stripe following an
# attempt to connect an account to the instance using the OAuth Connection Flow
# https://stripe.com/docs/connect/standard-accounts#oauth-flow

module Stripe
  class AccountConnector
    attr_reader :user, :params

    def initialize(user, params)
      @user = user
      @params = params
    end

    def create_account
      return false if connection_cancelled_by_user?

      raise StripeError, params["error_description"] unless params["code"]
      raise CanCan::AccessDenied unless state.key?("enterprise_id")

      # Local authorisation issue, so request disconnection from Stripe
      deauthorize unless user_has_permission_to_connect?

      StripeAccount.create(
        stripe_user_id: token.stripe_user_id,
        stripe_publishable_key: token.stripe_publishable_key,
        enterprise: enterprise
      )
    end

    def connection_cancelled_by_user?
      params[:action] == "connect_callback" && params[:error] == "access_denied"
    end

    def enterprise
      @enterprise ||= Enterprise.find_by(permalink: state["enterprise_id"])
    end

    private

    def state
      # Returns the original payload
      key = Openfoodnetwork::Application.config.secret_token
      JWT.decode(params["state"], key, true, algorithm: 'HS256')[0]
    end

    def token
      # Request an access token based on the code provided
      @token ||= OAuth.token(grant_type: 'authorization_code', code: params["code"])
    end

    def deauthorize
      OAuth.deauthorize(stripe_user_id: token.stripe_user_id)
      raise CanCan::AccessDenied
    end

    def user_has_permission_to_connect?
      user.enterprises.include?(enterprise) || user.admin?
    end
  end
end
