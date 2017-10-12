require 'stripe/webhook_handler'

module Stripe
  class WebhooksController < BaseController
    protect_from_forgery except: :create

    # POST /stripe/webhook
    def create
      # TODO is there a sensible way to confirm this webhook call is actually from Stripe?
      handler = WebhookHandler.new(params)
      result = handler.handle

      render nothing: true, status: status_mappings[result]
    end

    private

    # Stripe interprets a 4xx or 3xx response as a failure to receive the webhook,
    # and will stop sending events if too many of these are returned.
    def status_mappings
      {
        success: 200,
        failure: 202,
        silent_fail: 204
      }
    end
  end
end
