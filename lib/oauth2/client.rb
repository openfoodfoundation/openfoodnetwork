require 'oauth2'
OAuth2::Client.class_eval do
  def deauthorize_url(params = nil)
   connection.build_url(options[:deauthorize_url]).to_s
  end

  def deauthorize(account)
    client_object = self.dup
    client_object.options[:stripe_user_id] = account
    @deauthorize ||= OAuth2::Strategy::Deauthorize.new(client_object)
  end

  def deauthorize_request(params)
    headers = params.delete(:headers)
    opts = {}
    opts[:body] = params
    opts[:headers] = {'Content-Type' => 'application/x-www-form-urlencoded'}
    opts[:headers].merge!(headers) if headers
    request(:post, deauthorize_url, opts)
  end
end
