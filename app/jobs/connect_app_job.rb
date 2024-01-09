# frozen_string_literal: true

class ConnectAppJob < ApplicationJob
  include CableReady::Broadcaster

  def perform(app, token, channel: nil)
    url = "https://n8n.openfoodnetwork.org.uk/webhook/regen/connect-enterprise"
    event = "connect-app"
    enterprise = app.enterprise
    payload = {
      '@id': DfcBuilder.urls.enterprise_url(enterprise.id),
      access_token: token,
    }

    response = WebhookDeliveryJob.perform_now(url, event, payload)
    app.update!(data: JSON.parse(response))

    return unless channel

    selector = "#edit_enterprise_#{enterprise.id} #connected-app-discover-regen"
    html = ApplicationController.render(
      partial: "admin/enterprises/form/connected_apps",
      locals: { enterprise: },
    )

    cable_ready[channel].morph(selector:, html:).broadcast
  end
end
