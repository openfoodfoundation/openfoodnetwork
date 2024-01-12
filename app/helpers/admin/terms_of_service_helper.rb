# frozen_string_literal: true

module Admin
  module TermsOfServiceHelper
    def tos_need_accepting?
      return false unless spree_user_signed_in?

      return false if Spree::Config.enterprises_require_tos == false

      return false if TermsOfServiceFile.current.nil?

      !accepted_tos?
    end

    private

    def accepted_tos?
      file_uploaded_at = TermsOfServiceFile.updated_at

      current_spree_user.terms_of_service_accepted_at.present? &&
        current_spree_user.terms_of_service_accepted_at > file_uploaded_at &&
        current_spree_user.terms_of_service_accepted_at < DateTime.now
    end
  end
end
