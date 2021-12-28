# frozen_string_literal: true

class TermsOfService
  def self.tos_accepted?(customer, distributor = nil)
    return false unless accepted_at = customer&.terms_and_conditions_accepted_at

    accepted_at > if distributor
                    distributor.terms_and_conditions_updated_at
                  else
                    TermsOfServiceFile.updated_at
                  end
  end

  def self.platform_terms_required?
    Spree::Config.shoppers_require_tos
  end

  def self.terms_and_conditions_activated?(distributor)
    distributor.terms_and_conditions.file?
  end
end
