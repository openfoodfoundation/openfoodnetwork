# Base controller for OFN's API
# Includes the minimum machinery required by ActiveModelSerializers
module Api
  class BaseController < Spree::Api::BaseController
    # Need to include these because Spree::Api::BaseContoller inherits
    # from ActionController::Metal rather than ActionController::Base
    # and they are required by ActiveModelSerializers
    include ActionController::Serialization
    include ActionController::UrlFor
    include Rails.application.routes.url_helpers
    use_renderers :json
  end
end
