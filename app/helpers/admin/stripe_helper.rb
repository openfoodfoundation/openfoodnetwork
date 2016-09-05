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

  def get_token(code, options={params: {scope: 'read_write'}})
    @client.get_token(code, options)
  end
end
