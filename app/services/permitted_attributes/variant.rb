# frozen_string_literal: true

module PermittedAttributes
  class Variant
    def self.attributes
      [
        :id, :sku, :on_hand, :on_demand, :shipping_category_id,
        :price, :unit_value, :unit_description,
        :display_name, :display_as, :tax_category_id,
        :weight, :height, :width, :depth, :taxon_ids, :primary_taxon_id,
        :supplier_id
      ]
    end
  end
end
