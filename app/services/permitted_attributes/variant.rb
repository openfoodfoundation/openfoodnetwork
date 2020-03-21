# frozen_string_literal: true

module PermittedAttributes
  class Variant
    def self.attributes
      [
        :id, :sku, :on_hand, :on_demand,
        :cost_price, :price, :unit_value, :unit_description,
        :display_name, :display_as,
        :weight, :height, :width, :depth
      ]
    end
  end
end
