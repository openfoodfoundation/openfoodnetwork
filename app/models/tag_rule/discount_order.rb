class TagRule::DiscountOrder < TagRule
  calculated_adjustments

  private

  # Warning: this should only EVER be called via TagRule#apply
  def apply!
    percentage = "%.2f" % (calculator.preferred_flat_percent * -1)
    label = I18n.t("tag_rules.discount_order.label", percentage: percentage)
    create_adjustment(label, subject, subject)
  end

  def subject_class
    Spree::Order
  end

  def additional_requirements_met?
    return false if already_applied?
    true
  end

  def already_applied?
    subject.adjustments.where(originator_id: id, originator_type: "TagRule").any?
  end
end
