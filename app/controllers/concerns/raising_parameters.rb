# frozen_string_literal: true

# The API uses strict parameter checking.
#
# We want to raise errors when unused or unpermitted parameters are given
# to the API. You then know straight away when a parameter isn't used.
module RaisingParameters
  extend ActiveSupport::Concern

  # ActionController manages this config on a per-class basis. The subclass
  # enables us to raise errors only here and not in the rest of the app.
  class Parameters < ActionController::Parameters
    def self.action_on_unpermitted_parameters
      :raise
    end
  end

  # We override the params method so that we always use the strict parameters.
  # We could rename this method if we need access to the orginal as well.
  def params
    Parameters.new(super.to_unsafe_hash)
  end
end
