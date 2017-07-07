# Encapsulation of logic used to handle the response from Stripe following an
# attempt to connect an account to the instance using the OAuth Connection Flow
# https://stripe.com/docs/connect/standard-accounts#oauth-flow

module Stripe
  class AccountConnector
    attr_reader :oauth_response, :enterprise, :user, :params

    def initialize(user, params)
      @user = user
      @params = params

      raise StripeError, params["error_description"] unless params["code"]
      raise CanCan::AccessDenied unless state.keys.include? "enterprise_id"

      # Request an access token based on the code provided
      @oauth_response = OAuth.request_access_token(params["code"])

      # Find the Enterprise
      @enterprise = Enterprise.find_by_permalink(state["enterprise_id"])

      return if user.enterprises.include?(enterprise) || user.admin?

      # Local authorisation issue, so request disconnection from Stripe
      OAuth.deauthorize(oauth_response["stripe_user_id"])
      raise CanCan::AccessDenied
    end

    def create_account
      StripeAccount.create(
        stripe_user_id: oauth_response["stripe_user_id"],
        stripe_publishable_key: oauth_response["stripe_publishable_key"],
        enterprise: enterprise
      )
    end

    private

    def state
      OAuth.send(:jwt_decode, params["state"])
    end
  end
end
