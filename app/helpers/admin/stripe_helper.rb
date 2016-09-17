module Admin
  module StripeHelper
    class << self
      attr_accessor :client, :options
    end
    @options = {
      :site => 'https://connect.stripe.com',
      :authorize_url => '/oauth/authorize',
      :token_url => '/oauth/token'
    }
    @client = OAuth2::Client.new(
      ENV['STRIPE_CLIENT_ID'],
      ENV['STRIPE_INSTANCE_SECRET_KEY'],
      options
    )

    def get_stripe_token(code, options={params: {scope: 'read_write'}})
      StripeHelper.client.get_token(code, options)
    end

    def authorize_stripe(enterprise_id, options={})
      options = options.merge({enterprise_id: enterprise_id})
      # State param will be passed back after auth
      StripeHelper.client.auth_code.authorize_url(state: options)
    end
  end
end
