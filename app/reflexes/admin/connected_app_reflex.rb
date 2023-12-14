# frozen_string_literal: true

module Admin
  class ConnectedAppReflex < ApplicationReflex
    def create
      enterprise = Enterprise.find(element.dataset.enterprise_id)
      authorize! :admin, enterprise
      app = ConnectedApp.create!(enterprise_id: enterprise.id)

      ConnectAppJob.perform_later(
        app, current_user.spree_api_key,
        channel: SessionChannel.for_request(request),
      )
    end
  end
end
