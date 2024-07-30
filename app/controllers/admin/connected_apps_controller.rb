# frozen_string_literal: true

module Admin
  class ConnectedAppsController < ApplicationController
    def create
      authorize! :admin, enterprise

      attributes = {}
      attributes[:type] = connected_app_params[:type] if connected_app_params[:type]

      app = ConnectedApp.create!(enterprise_id: enterprise.id, **attributes)
      app.connect(api_key: spree_current_user.spree_api_key,
                  channel: SessionChannel.for_request(request))

      render_panel
    end

    def destroy
      authorize! :admin, enterprise

      app = enterprise.connected_apps.find(params.require(:id))
      app.destroy

      render_panel
    end

    private

    def enterprise
      @enterprise ||= Enterprise.find(params.require(:enterprise_id))
    end

    def render_panel
      redirect_to "#{edit_admin_enterprise_path(enterprise)}#/connected_apps_panel"
    end

    def connected_app_params
      params.permit(:type)
    end
  end
end
