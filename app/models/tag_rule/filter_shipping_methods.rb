class TagRule::FilterShippingMethods < TagRule
  preference :matched_shipping_methods_visibility, :string, default: "visible"
  preference :shipping_method_tags, :string, default: ""

  attr_accessible :preferred_matched_shipping_methods_visibility, :preferred_shipping_method_tags

  private

  # Warning: this should only EVER be called via TagRule#apply
  def apply!
    unless preferred_matched_shipping_methods_visibility == "visible"
      subject.reject!{ |sm| tags_match?(sm) }
    end
  end

  def apply_default!
    if preferred_matched_shipping_methods_visibility == "visible"
      subject.reject!{ |sm| tags_match?(sm) }
    end
  end

  def tags_match?(shipping_method)
    shipping_method_tags = shipping_method.andand.tag_list || []
    preferred_tags = preferred_shipping_method_tags.split(",")
    ( shipping_method_tags & preferred_tags ).any?
  end

  def subject_class_matches?
    subject.class == Array &&
    subject.all? { |i| i.class == Spree::ShippingMethod }
  end
end
