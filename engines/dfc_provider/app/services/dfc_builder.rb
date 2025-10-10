# frozen_string_literal: true

class DfcBuilder
  # The DFC sees "empty" stock as unlimited.
  # http://static.datafoodconsortium.org/conception/DFC%20-%20Business%20rules.pdf
  def self.stock_limitation(variant)
    variant.on_demand ? nil : variant.total_on_hand
  end

  def self.urls
    DfcProvider::Engine.routes.url_helpers
  end
end
