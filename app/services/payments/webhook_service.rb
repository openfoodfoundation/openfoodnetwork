# frozen_string_literal: true

# Create a webhook payload for a payment status event.
# The payload will be delivered asynchronously.

module Payments
  class WebhookService
    def self.create_webhook_job(payment:, event:, at:)
      order = payment.order
      payload = WebhookPayload.new(payment:, order:, enterprise: order.distributor).to_hash

      coordinator = payment.order.order_cycle.coordinator
      urls = WebhookUrlsService.for_coordinator(coordinator,
                                                webhook_type: "payment_status_changed")
      urls.each do |url|
        WebhookDeliveryJob.perform_later(url, event, payload, at:)
      end
    end
  end
end
