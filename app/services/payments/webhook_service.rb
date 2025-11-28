# frozen_string_literal: true

# Create a webhook payload for an payment status event.
# The payload will be delivered asynchronously.

module Payments
  class WebhookService
    def self.create_webhook_job(payment:, event:, at:)
      order = payment.order
      enterprise = order.distributor

      line_items = order.line_items.map do |li|
        li.slice(:quantity, :price)
          .merge(
            tax_category_name: li.tax_category&.name,
            product_name: li.product.name,
            name_to_display: li.display_name,
            unit_to_display: li.unit_presentation
          )
      end

      payload = {
        payment: payment.slice(:updated_at, :amount, :state),
        enterprise: enterprise.slice(:abn, :acn, :name)
          .merge(address: enterprise.address.slice(:address1, :address2, :city, :zipcode)),
        order: order.slice(:total, :currency).merge(line_items: line_items)
      }

      coordinator = order.order_cycle.coordinator
      webhook_urls(coordinator).each do |url|
        WebhookDeliveryJob.perform_later(url, event, payload, at:)
      end
    end

    def self.webhook_urls(coordinator)
      # url for coordinator owner
      webhook_urls = coordinator.owner.webhook_endpoints.payment_status.map(&:url)

      # plus url for coordinator manager (ignore duplicate)
      users_webhook_urls = coordinator.users.flat_map do |user|
        user.webhook_endpoints.payment_status.map(&:url)
      end

      webhook_urls | users_webhook_urls
    end
  end
end
