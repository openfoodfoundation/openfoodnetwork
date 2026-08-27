# frozen_string_literal: true

class DfcBuilder
  def self.stock_limitation(variant)
    variant.on_demand ? nil : variant.total_on_hand
  end

  def self.urls
    DfcProvider::Engine.routes.url_helpers
  end

  def self.semantic_id(item)
    item.respond_to?(:semanticId) ? item.semanticId : item.to_s
  end
end
