# frozen_string_literal: true

# Records a webhook url to send notifications to
class WebhookEndpoint < ApplicationRecord
  validates :url, presence: true
end
