# frozen_string_literal: true

# API controllers inherit from ActionController::Metal to keep them slim and fast.
# This concern adds the minimum requirements needed to use Action Caching in the API.

module ApiActionCaching
  extend ActiveSupport::Concern

  included do
    include ActionController::Caching
    include ActionController::Caching::Actions
    include ActionView::Layouts

    # These configs are not assigned to the controller automatically with ActionController::Metal
    self.cache_store = Rails.configuration.cache_store
    self.perform_caching = true

    # ActionController::Caching asks for a controller's layout, but they're not used in the API
    layout false
  end
end
