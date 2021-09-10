# frozen_string_literal: true

class TagRule::FilterShippingMethods < TagRule
  preference :matched_shipping_methods_visibility, :string, default: "visible"
  preference :shipping_method_tags, :string, default: ""

  def reject_matched?
    preferred_matched_shipping_methods_visibility != "visible"
  end

  def tags_match?(shipping_method)
    shipping_method_tags = shipping_method&.tag_list || []
    preferred_tags = preferred_shipping_method_tags.split(",")
    ( shipping_method_tags & preferred_tags ).any?
  end
end
