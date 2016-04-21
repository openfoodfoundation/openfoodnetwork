class TagRule::FilterProducts < TagRule
  preference :matched_variants_visibility, :string, default: "visible"
  preference :variant_tags, :string, default: ""

  attr_accessible :preferred_matched_variants_visibility, :preferred_variant_tags

  private

  # Warning: this should only EVER be called via TagRule#apply
  def apply!
    unless preferred_matched_variants_visibility == "visible"
      subject.reject! do |product|
        product["variants"].reject!{ |v| tags_match?(v) }
        product["variants"].empty?
      end
    end
  end

  def apply_default!
    if preferred_matched_variants_visibility == "visible"
      subject.reject! do |product|
        product["variants"].reject!{ |v| tags_match?(v) }
        product["variants"].empty?
      end
    end
  end

  def tags_match?(variant)
    variant_tags = variant.andand["tag_list"] || []
    preferred_tags = preferred_variant_tags.split(",")
    ( variant_tags & preferred_tags ).any?
  end

  def subject_class_matches?
    subject.class == Array
  end
end
