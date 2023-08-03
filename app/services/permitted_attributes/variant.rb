# frozen_string_literal: true

module PermittedAttributes
  class Variant
    def self.attributes
      [
        :id, :sku, :on_hand, :on_demand,
        :price, :unit_value, :unit_description,
        :display_name, :display_as, :tax_category_id,
        :weight, :height, :width, :depth
      ]
    end
  end
end
