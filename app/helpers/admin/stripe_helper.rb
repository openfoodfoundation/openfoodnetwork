# require File.join(Rails.root, '/lib/oauth2/strategy/deauthorize')
# require File.join(Rails.root, '/lib/oauth2/client')
# require 'oauth2'
module Admin
  module StripeHelper

    class << self
      attr_accessor :client, :options
    end

    @options = {
      :site => 'https://connect.stripe.com',
      :authorize_url => '/oauth/authorize',
      :deauthorize_url => '/oauth/deauthorize',
      :token_url => '/oauth/token'
    }

    @client = OAuth2::Client.new(
      ENV['STRIPE_CLIENT_ID'],
      ENV['STRIPE_INSTANCE_SECRET_KEY'],
      options
    )
    # Stripe ruby bindings used for non-Connect functionality
    Stripe.api_key = ENV['STRIPE_INSTANCE_SECRET_KEY']

    def get_stripe_token(code, options={scope: 'read_write'})
      StripeHelper.client.auth_code.get_token(code, options)
    end

    def authorize_stripe(enterprise_id, options={})
      options = options.merge({enterprise_id: enterprise_id})
      jwt = jwt_encode options
      # State param will be passed back after auth
      StripeHelper.client.auth_code.authorize_url(state: jwt)
    end

    def deauthorize_stripe(account_id)
      stripe_account = StripeAccount.find(account_id)
      if stripe_account
        # If the account is only connected to one Enterprise, make a request to remove it on the Stripe side
        if StripeAccount.where(stripe_user_id: stripe_account.stripe_user_id).size == 1
          response = deauthorize_request_for_stripe_id(stripe_account.stripe_user_id)
          if response # Response from OAuth2 only returned if successful
            stripe_account.destroy
          end
        else
          stripe_account.destroy
        end
      end
    end

    def fetch_event_from_stripe(request)
      event_json = JSON.parse(request.body.read)
      JSON.parse(Stripe::Event.retrieve(event_json["id"]))
    end

    def deauthorize_request_for_stripe_id(id)
      StripeHelper.client.deauthorize(id).deauthorize_request
    end

    private
    def jwt_encode payload
      JWT.encode(payload, Openfoodnetwork::Application.config.secret_token, 'HS256')
    end

    def jwt_decode token
      JWT.decode(token, Openfoodnetwork::Application.config.secret_token, 'HS256')[0] # only returns the original payload
    end
  end
end
