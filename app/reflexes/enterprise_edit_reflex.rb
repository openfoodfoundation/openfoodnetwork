# frozen_string_literal: false

class EnterpriseEditReflex < ApplicationReflex
  def remove_terms_and_conditions
    @enterprise = Enterprise.find(element.dataset['enterprise-id'])
    throw :forbidden unless can?(:remove_terms_and_conditions, @enterprise)

    @enterprise.terms_and_conditions.purge_later
  end
end
