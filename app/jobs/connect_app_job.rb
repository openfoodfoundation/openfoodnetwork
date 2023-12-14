# frozen_string_literal: true

class ConnectAppJob < ApplicationJob
  def perform(app, token)
    url = "https://n8n.openfoodnetwork.org.uk/webhook/regen/connect-enterprise"
    event = "connect-app"
    payload = {
      enterprise_id: app.enterprise_id,
      access_token: token,
    }

    response = WebhookDeliveryJob.perform_now(url, event, payload)
    app.update!(data: JSON.parse(response))
  end
end
