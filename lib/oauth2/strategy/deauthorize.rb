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
