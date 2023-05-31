# frozen_string_literal: true

module TermsAndConditionsHelper
  def link_to_platform_terms
    link_to(t("terms_of_service"), TermsOfServiceFile.current_url, target: "_blank",
                                                                   rel: "noopener")
  end

  def any_terms_required?(distributor)
    TermsOfService.required?(distributor)
  end

  def platform_terms_required?
    TermsOfService.platform_terms_required?
  end

  def distributor_terms_required?
    TermsOfService.distributor_terms_required?(current_order.distributor)
  end

  def all_terms_and_conditions_already_accepted?
    platform_tos_already_accepted? && terms_and_conditions_already_accepted?
  end

  def platform_tos_already_accepted?
    TermsOfService.tos_accepted?(spree_current_user&.customer_of(current_order.distributor))
  end

  def terms_and_conditions_already_accepted?
    TermsOfService.tos_accepted?(
      spree_current_user&.customer_of(current_order.distributor),
      current_order.distributor
    )
  end
end
