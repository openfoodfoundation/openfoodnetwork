# frozen_string_literal: true

require "faraday"
require "private_address_check"
require "private_address_check/tcpsocket_ext"

# Deliver a webhook payload
# As a delayed job, it can run asynchronously and handle retries.
class WebhookDeliveryJob < ApplicationJob
  # General failed request error that we're going to use to signal
  # the job runner to retry our webhook worker.
  class FailedWebhookRequestError < StandardError; end

  queue_as :default

  def perform(url, event, payload)
    body = {
      id: job_id,
      at: Time.zone.now.to_s,
      event: event,
      data: payload,
    }

    # Request user-submitted url, preventing any private connections being made
    # (SSRF).
    # This method may allow the socket to open, but is necessary in order to
    # protect from TOC/TOU.
    # Note that private_address_check provides some methods for pre-validating,
    # but they're not as comprehensive and so unnecessary here. Simply
    # momentarily opening sockets probably can't cause DoS or other damage.
    PrivateAddressCheck.only_public_connections do
      notify_endpoint(url, body)
    end
  end

  def notify_endpoint(url, body)
    connection = Faraday.new(
      request: { timeout: 30 },
      headers: {
        'User-Agent' => 'openfoodnetwork_webhook/1.0',
        'Content-Type' => 'application/json',
      }
    )
    response = connection.post(url, body.to_json)

    # Raise a failed request error and let job runner handle retrying.
    # In theory, only 5xx errors should be retried, but who knows.
    raise FailedWebhookRequestError, response.status.to_s unless response.success?
  end
end
