# frozen_string_literal: false

class EnterpriseEditReflex < ApplicationReflex
  delegate :current_user, to: :connection

  def remove_terms_and_conditions
    @enterprise = Enterprise.find(element.dataset['enterprise-id'])
    ability = Spree::Ability.new(current_user).can? :remove_terms_and_conditions, @enterprise
    throw :forbidden unless ability
    @enterprise.terms_and_conditions.purge_later
  end
end
