class TagRule::FilterPaymentMethods < TagRule
  preference :matched_payment_methods_visibility, :string, default: "visible"
  preference :payment_method_tags, :string, default: ""

  attr_accessible :preferred_matched_payment_methods_visibility, :preferred_payment_method_tags

  private

  # Warning: this should only EVER be called via TagRule#apply
  def apply!
    unless preferred_matched_payment_methods_visibility == "visible"
      subject.reject!{ |pm| tags_match?(pm) }
    end
  end

  def apply_default!
    if preferred_matched_payment_methods_visibility == "visible"
      subject.reject!{ |pm| tags_match?(pm) }
    end
  end

  def tags_match?(payment_method)
    payment_method_tags = payment_method.andand.tag_list || []
    preferred_tags = preferred_payment_method_tags.split(",")
    ( payment_method_tags & preferred_tags ).any?
  end

  def subject_class_matches?
    subject.class == Array &&
    subject.all? { |i| i.class < Spree::PaymentMethod }
  end
end
