class TagRule::DiscountOrder < TagRule
  include Spree::Core::CalculatedAdjustments

  private

  # Warning: this should only EVER be called via TagRule#apply
  def apply!
    create_adjustment(I18n.t("discount"), subject, subject)
  end

  def subject_class_matches?
    subject.class == Spree::Order
  end

  def additional_requirements_met?
    return false if already_applied?
    true
  end

  def already_applied?
    subject.adjustments.where(originator_id: id, originator_type: "TagRule").any?
  end
end
