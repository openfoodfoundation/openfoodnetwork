# frozen_string_literal: true

module Admin
  class ConnectedAppReflex < ApplicationReflex
    def create
      enterprise = Enterprise.find(element.dataset.enterprise_id)
      authorize! :admin, enterprise
      app = ConnectedApp.create!(enterprise_id: enterprise.id)

      selector = "#edit_enterprise_#{enterprise.id} #connected-app-discover-regen"
      html = ApplicationController.render(
        partial: "admin/enterprises/form/connected_apps",
        locals: { enterprise: },
      )

      # Avoid race condition by sending before enqueuing job:
      cable_ready.morph(selector:, html:).broadcast

      ConnectAppJob.perform_later(
        app, current_user.spree_api_key,
        channel: SessionChannel.for_request(request),
      )
      morph :nothing
    end
  end
end
