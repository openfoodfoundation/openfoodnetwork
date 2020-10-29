# frozen_string_literal: true

module TermsAndConditionsHelper
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
