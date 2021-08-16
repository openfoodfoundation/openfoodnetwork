# frozen_string_literal: true

module CablecarResponses
  extend ActiveSupport::Concern

  included do
    include CableReady::Broadcaster
  end

  private

  def partial(path, options = {})
    { html: render_to_string(partial: path, **options) }
  end
end
