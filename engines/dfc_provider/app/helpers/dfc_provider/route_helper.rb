# frozen_string_literal: true

# Helper used to easily build DFC routes inside classes
# which need it such as serilaizers.
module DfcProvider
  module RouteHelper
    def host
      Rails.application.config.action_mailer.default_url_options[:host]
    end

    def dfc_provider_routes
      DfcProvider::Engine.routes.url_helpers
    end
  end
end
