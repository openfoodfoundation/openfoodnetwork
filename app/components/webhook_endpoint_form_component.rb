# frozen_string_literal: true

class WebhookEndpointFormComponent < ViewComponent::Base
  def initialize(webhooks:, webhook_type:)
    @webhooks = webhooks
    @webhook_type = webhook_type
  end

  private

  attr_reader :webhooks, :webhook_type

  # The webhook types we can send test data for.
  def testable?
    webhook_type.in?(%w(payment_status_changed order_payment_due))
  end
end
