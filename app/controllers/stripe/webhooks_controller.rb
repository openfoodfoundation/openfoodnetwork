require 'stripe/webhook_handler'

module Stripe
  class WebhooksController < BaseController
    protect_from_forgery except: :create

    # POST /stripe/webhook
    def create
      # TODO is there a sensible way to confirm this webhook call is actually from Stripe?
      handler = WebhookHandler.new(params)
      status = handler.handle ? 200 : 204

      render nothing: true, status: status
    end
  end
end
