class TagRule::FilterPaymentMethods < TagRule
  preference :matched_payment_methods_visibility, :string, default: "visible"
  preference :payment_method_tags, :string, default: ""

  attr_accessible :preferred_matched_payment_methods_visibility, :preferred_payment_method_tags

  def tags_match?(payment_method)
    payment_method_tags = payment_method.andand.tag_list || []
    preferred_tags = preferred_payment_method_tags.split(",")
    ( payment_method_tags & preferred_tags ).any?
  end

  def reject_matched?
    preferred_matched_payment_methods_visibility != "visible"
  end
end
