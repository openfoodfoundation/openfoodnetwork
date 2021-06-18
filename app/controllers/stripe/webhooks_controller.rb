# frozen_string_literal: true

require 'stripe/webhook_handler'

module Stripe
  class WebhooksController < BaseController
    protect_from_forgery except: :create
    before_action :verify_webhook

    # POST /stripe/webhooks
    def create
      handler = WebhookHandler.new(@event)
      result = handler.handle

      render body: nil, status: status_mappings[result] || 200
    end

    private

    def verify_webhook
      payload = request.raw_post
      signature = request.headers["HTTP_STRIPE_SIGNATURE"]
      @event = Webhook.construct_event(payload, signature, Stripe.endpoint_secret)
    rescue JSON::ParserError
      render body: nil, status: :bad_request
    rescue Stripe::SignatureVerificationError
      render body: nil, status: :unauthorized
    end

    # Stripe interprets a 4xx or 3xx response as a failure to receive the webhook,
    # and will stop sending events if too many of either of these are returned.
    def status_mappings
      {
        success: 200, # The event was handled successfully
        unknown: 202, # The event was of an unknown type
        ignored: 204  # No action was taken in response to the event
      }
    end
  end
end
