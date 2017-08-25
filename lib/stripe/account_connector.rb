# Encapsulation of logic used to handle the response from Stripe following an
# attempt to connect an account to the instance using the OAuth Connection Flow
# https://stripe.com/docs/connect/standard-accounts#oauth-flow

module Stripe
  class AccountConnector
    attr_reader :token, :enterprise, :user, :params

    def initialize(user, params)
      @user = user
      @params = params

      raise StripeError, params["error_description"] unless params["code"]
      raise CanCan::AccessDenied unless state.keys.include? "enterprise_id"

      # Request an access token based on the code provided
      @token = OAuth.token(grant_type: 'authorization_code', code: params["code"])

      # Find the Enterprise
      @enterprise = Enterprise.find_by_permalink(state["enterprise_id"])

      return if user.enterprises.include?(enterprise) || user.admin?

      # Local authorisation issue, so request disconnection from Stripe
      OAuth.deauthorize(stripe_user_id: token.stripe_user_id)
      raise CanCan::AccessDenied
    end

    def create_account
      StripeAccount.create(
        stripe_user_id: token.stripe_user_id,
        stripe_publishable_key: token.stripe_publishable_key,
        enterprise: enterprise
      )
    end

    private

    def state
      # Returns the original payload
      key = Openfoodnetwork::Application.config.secret_token
      JWT.decode(params["state"], key, true, algorithm: 'HS256')[0]
    end
  end
end
