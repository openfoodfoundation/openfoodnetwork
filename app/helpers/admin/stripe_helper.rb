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
      # State param will be passed back after auth
      StripeHelper.client.auth_code.authorize_url(state: options)
    end

    def deauthorize_stripe(account_id)
      stripe_account = StripeAccount.find(account_id)
      if stripe_account
        response = StripeHelper.client.deauthorize(stripe_account.stripe_user_id).deauthorize_request
        if response # Response from OAuth2 only returned if successful
          stripe_account.destroy
        end
      end
    end

    def fetch_event_from_stripe(request)
      event_json = JSON.parse(request.body.read)
      JSON.parse(Stripe::Event.retrieve(event_json["id"]))
    end
  end
end
