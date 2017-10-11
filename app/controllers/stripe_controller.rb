require 'stripe/webhook_handler'

class StripeController < BaseController
  def webhook
    # TODO is there a sensible way to confirm this webhook call is actually from Stripe?
    handler = Stripe::WebhookHandler.new(params)
    status = handler.handle ? 200 : 204

    render nothing: true, status: status
  end
end
