# frozen_string_literal: true

# Records a webhook url to send notifications to
class WebhookEndpoint < ApplicationRecord
  WEBHOOK_TYPES = %w(order_cycle_opened payment_status_changed).freeze

  validates :url, presence: true
  validates :webhook_type, presence: true, inclusion: { in: WEBHOOK_TYPES }
end
