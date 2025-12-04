# frozen_string_literal: true

class WebhookEndpointFormComponent < ViewComponent::Base
  def initialize(webhooks:, webhook_type:)
    @webhooks = webhooks
    @webhook_type = webhook_type
  end

  private

  attr_reader :webhooks, :webhook_type

  def is_webhook_payment_status?
    webhook_type == "payment_status_changed"
  end
end
