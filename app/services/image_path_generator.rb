# frozen_string_literal: true

class ImagePathGenerator
  # Since Rails 4 has adjusted the way assets paths are handled, we have to access certain
  # asset-based helpers like this when outside of a view or controller context.
  # See: https://stackoverflow.com/a/16609815
  def self.call(path)
    ActionController::Base.helpers.image_path(path)
  end
end
