# frozen_string_literal: true

module Admin
  class ConnectedAppReflex < ApplicationReflex
    def create
      enterprise = Enterprise.find(element.dataset.enterprise_id)
      authorize! :admin, enterprise
      ConnectedApp.create!(enterprise_id: enterprise.id)
    end
  end
end
