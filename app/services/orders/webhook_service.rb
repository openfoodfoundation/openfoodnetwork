# frozen_string_literal: true

# Notify configured webhook endpoints when an order is placed while a payment is
# still due, so an integration can initiate an external payment flow (e.g. a
# local currency) without the Open Food Network natively supporting it.
# The payload is delivered asynchronously.

module Orders
  class WebhookService
    def self.create_payment_due_job(order:)
      return if order.order_cycle.nil?

      payment = order.pending_payments.first
      payload = WebhookPayload.new(order:, payment:, enterprise: order.distributor).to_hash

      coordinator = order.order_cycle.coordinator
      Payments::WebhookService.webhook_urls(coordinator).each do |url|
        WebhookDeliveryJob.perform_later(url, "order.payment_due", payload)
      end
    end
  end
end
