# frozen_string_literal: true

# Create a webhook payload for a payment status event.
# The payload will be delivered asynchronously.

module Payments
  class WebhookService
    def self.create_webhook_job(payment:, event:, at:)
      order = payment.order
      payload = WebhookPayload.new(payment:, order:, enterprise: order.distributor).to_hash

      coordinator = payment.order.order_cycle.coordinator
      webhook_urls(coordinator).each do |url|
        WebhookDeliveryJob.perform_later(url, event, payload, at:)
      end
    end

    def self.webhook_urls(coordinator)
      # url for coordinator owner
      webhook_urls = coordinator.owner.webhook_endpoints.payment_status.pluck(:url)

      # plus url for coordinator manager (ignore duplicate)
      users_webhook_urls = coordinator.users.flat_map do |user|
        user.webhook_endpoints.payment_status.pluck(:url)
      end

      webhook_urls | users_webhook_urls
    end
  end
end
