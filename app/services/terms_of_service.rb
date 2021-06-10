class TermsOfService
  def self.tos_accepted?(customer, distributor = nil)
    return false unless accepted_at = customer&.terms_and_conditions_accepted_at

    if distributor
      accepted_at > distributor.terms_and_conditions_updated_at
    else
      accepted_at > TermsOfServiceFile.updated_at
    end
  end
end
