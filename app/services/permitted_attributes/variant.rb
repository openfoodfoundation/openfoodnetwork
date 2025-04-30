# frozen_string_literal: true

module PermittedAttributes
  class Variant
    def self.attributes
      [
        :id, :sku, :on_hand, :on_hand_desired, :on_demand, :on_demand_desired,
        :shipping_category_id, :price, :unit_value,
        :unit_description, :variant_unit, :variant_unit_name, :variant_unit_scale, :display_name,
        :display_as, :tax_category_id, :weight, :height, :width, :depth, :taxon_ids,
        :primary_taxon_id, :supplier_id, :tag_list
      ]
    end
  end
end
