# frozen_string_literal: true

class TagRule
  class FilterVariants < TagRule
    preference :matched_variants_visibility, :string, default: "visible"
    preference :variant_tags, :string, default: ""

    def tags_match?(variant)
      variant_tags = variant&.[]("tag_list") || []
      preferred_tags = preferred_variant_tags.split(",")
      variant_tags.intersect?(preferred_tags)
    end

    def reject_matched?
      preferred_matched_variants_visibility != "visible"
    end

    def tags
      preferred_variant_tags
    end
  end
end
