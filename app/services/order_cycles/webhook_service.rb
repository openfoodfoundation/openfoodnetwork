# frozen_string_literal: true

# Create a webhook payload for an order cycle event.
# The payload will be delivered asynchronously.

module OrderCycles
  class WebhookService
    def self.create_webhook_job(order_cycle, event, at)
      webhook_payload = order_cycle
        .slice(:id, :name, :orders_open_at, :opened_at, :orders_close_at, :coordinator_id)
        .merge(coordinator_name: order_cycle.coordinator.name)

      # Endpoints for coordinator owner
      webhook_endpoints = order_cycle.coordinator.owner.webhook_endpoints.order_cycle_opened

      # Plus unique endpoints for distributor owners (ignore duplicates)
      webhook_endpoints |= order_cycle.distributors.map(&:owner).flat_map { |owner|
        owner.webhook_endpoints.order_cycle_opened
      }

      webhook_endpoints.each do |endpoint|
        WebhookDeliveryJob.perform_later(endpoint.url, event, webhook_payload, at:)
      end
    end
  end
end
