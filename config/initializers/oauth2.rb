Rails.application.config.to_prepare do
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

  module OAuth2
    module Strategy
      # Deauthorization Strategy -- for Stripe
      class Deauthorize < Base
        # The required query parameters for the authorize URL
        #
        def deauthorize_params(params = {})
          params.merge({  'client_id' => @client.id,
                          'stripe_user_id' => @client.options[:stripe_user_id]
                      })
        end

        def deauthorize_url(params = {})
         @client.deauthorize_url(deauthorize_params.merge(params))
        end

        def deauthorize_request(params = {})
          params = params.merge(deauthorize_params).merge(client_params)
          @client.deauthorize_request(params)
        end

      end
    end
  end
end
