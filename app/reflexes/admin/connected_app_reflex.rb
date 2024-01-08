# frozen_string_literal: true

module Admin
  class ConnectedAppReflex < ApplicationReflex
    def create
      authorize! :admin, enterprise

      app = ConnectedApp.create!(enterprise_id: enterprise.id)

      # Avoid race condition by sending before enqueuing job:
      broadcast_partial

      ConnectAppJob.perform_later(
        app, current_user.spree_api_key,
        channel: SessionChannel.for_request(request),
      )
      morph :nothing
    end

    def destroy
      authorize! :admin, enterprise

      app = enterprise.connected_apps.first
      app.destroy

      broadcast_partial

      WebhookDeliveryJob.perform_later(
        app.data["destroy"],
        "disconnect-app",
        nil
      )
      morph :nothing
    end

    private

    def enterprise
      @enterprise ||= Enterprise.find(element.dataset.enterprise_id)
    end

    def broadcast_partial
      selector = "#edit_enterprise_#{enterprise.id} #connected-app-discover-regen"
      html = ApplicationController.render(
        partial: "admin/enterprises/form/connected_apps",
        locals: { enterprise: },
      )

      # Avoid race condition by sending before enqueuing job:
      cable_ready.morph(selector:, html:).broadcast
    end
  end
end
