# frozen_string_literal: true

class ConnectAppJob < ApplicationJob
  include CableReady::Broadcaster

  def perform(app, token, channel: nil)
    url = I18n.t("connect_app.url")
    event = "connect-app"
    enterprise = app.enterprise
    payload = {
      '@id': DfcBuilder.urls.enterprise_url(enterprise.id),
      access_token: token,
    }

    response = WebhookDeliveryJob.perform_now(url, event, payload)
    app.update!(data: JSON.parse(response))

    return unless channel

    selector = "#connected-app-discover-regen.enterprise_#{enterprise.id}"
    html = ApplicationController.render(
      partial: "admin/enterprises/form/connected_apps/discover_regen",
      locals: { enterprise:, connected_app: enterprise.connected_apps.discover_regen.first },
    )

    cable_ready[channel].morph(selector:, html:).broadcast
  end
end
