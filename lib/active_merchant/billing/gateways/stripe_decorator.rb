# frozen_string_literal: true

# Here we bring commit 823faaeab0d6d3bd75ee037ec894ab7c9d95d3a9 from ActiveMerchant v1.98.0
# This is needed to make StripePaymentIntents work correctly
# This can be removed once we upgrade to ActiveMerchant v1.98.0
ActiveMerchant::Billing::StripeGateway.class_eval do
  def authorization_from(success, url, method, response)
    return response.fetch('error', {})['charge'] unless success

    if url == 'customers'
      [response['id'], response.dig('sources', 'data').first&.dig('id')].join('|')
    elsif method == :post &&
          (url.match(%r{customers/.*/cards}) || url.match(%r{payment_methods/.*/attach}))
      [response['customer'], response['id']].join('|')
    else
      response['id']
    end
  end
end
