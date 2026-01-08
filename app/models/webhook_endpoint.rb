# frozen_string_literal: true

# Records a webhook url to send notifications to
class WebhookEndpoint < ApplicationRecord
  WEBHOOK_TYPES = %w(order_cycle_opened payment_status_changed).freeze

  validates :url, presence: true
  validates :webhook_type, presence: true, inclusion: { in: WEBHOOK_TYPES }

  scope :order_cycle_opened, -> { where(webhook_type: "order_cycle_opened") }
  scope :payment_status, -> { where(webhook_type: "payment_status_changed") }
end
