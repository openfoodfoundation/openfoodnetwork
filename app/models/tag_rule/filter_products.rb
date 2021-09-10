# frozen_string_literal: true

class TagRule
  class FilterProducts < TagRule
    preference :matched_variants_visibility, :string, default: "visible"
    preference :variant_tags, :string, default: ""

    def self.tagged_children_for(product)
      product["variants"]
    end

    def tags_match?(variant)
      variant_tags = variant&.[]("tag_list") || []
      preferred_tags = preferred_variant_tags.split(",")
      (variant_tags & preferred_tags).any?
    end

    def reject_matched?
      preferred_matched_variants_visibility != "visible"
    end
  end
end
