# frozen_string_literal: true

module Admin
  class ConnectedAppsController < ApplicationController
    def create
      authorize! :admin, enterprise

      app = ConnectedApp.create!(enterprise_id: enterprise.id)

      ConnectAppJob.perform_later(
        app, spree_current_user.spree_api_key,
        channel: SessionChannel.for_request(request),
      )

      render_panel
    end

    def destroy
      authorize! :admin, enterprise

      app = enterprise.connected_apps.first
      app.destroy

      WebhookDeliveryJob.perform_later(
        app.data["destroy"],
        "disconnect-app",
        nil
      )

      render_panel
    end

    private

    def enterprise
      @enterprise ||= Enterprise.find(params.require(:enterprise_id))
    end

    def render_panel
      redirect_to "#{edit_admin_enterprise_path(enterprise)}#/connected_apps_panel"
    end
  end
end
