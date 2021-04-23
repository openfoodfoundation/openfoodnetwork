# frozen_string_literal: true

module TermsAndConditionsHelper
  def link_to_platform_terms
    link_to(t("terms_of_service"), Spree::Config.footer_tos_url, target: "_blank")
  end

  def render_terms_and_conditions
    if platform_terms_required? && terms_and_conditions_activated?
      render("checkout/all_terms_and_conditions")
    elsif platform_terms_required?
      render "checkout/platform_terms_of_service"
    elsif terms_and_conditions_activated?
      render "checkout/terms_and_conditions"
    end
  end

  def platform_terms_required?
    Spree::Config.shoppers_require_tos
  end

  def terms_and_conditions_activated?
    current_order.distributor.terms_and_conditions.file?
  end

  def terms_and_conditions_already_accepted?
    customer_terms_and_conditions_accepted_at = spree_current_user&.
      customer_of(current_order.distributor)&.terms_and_conditions_accepted_at

    customer_terms_and_conditions_accepted_at.present? &&
      (customer_terms_and_conditions_accepted_at >
        current_order.distributor.terms_and_conditions_updated_at)
  end
end
