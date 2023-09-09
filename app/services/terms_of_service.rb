# frozen_string_literal: true

class TermsOfService
  def self.tos_accepted?(customer, distributor = nil)
    return false unless accepted_at = customer&.terms_and_conditions_accepted_at

    return accepted_at > distributor.terms_and_conditions_blob.created_at if distributor

    return true unless TermsOfServiceFile.exists?

    accepted_at > TermsOfServiceFile.updated_at
  end

  def self.required?(distributor)
    platform_terms_required? || distributor_terms_required?(distributor)
  end

  def self.platform_terms_required?
    TermsOfServiceFile.exists? &&
      Spree::Config.shoppers_require_tos
  end

  def self.distributor_terms_required?(distributor)
    distributor.terms_and_conditions.attached?
  end
end
