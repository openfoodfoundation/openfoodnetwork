# frozen_string_literal: true

# Called by "ActiveSupport::Notifications" when an "ofn.payment_transition" occurs
# Event originate from Spree::Payment event machine
#
module Payments
  class StatusChangedListenerService
    def call(_name, started, _finished, _unique_id, payload)
      event = "payment.#{payload[:event]}"
      Payments::WebhookService.create_webhook_job(payment: payload[:payment], event:, at: started)
    end
  end
end
