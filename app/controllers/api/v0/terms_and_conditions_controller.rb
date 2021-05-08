# frozen_string_literal: true

module Api
  module V0
    class TermsAndConditionsController < Api::V0::EnterpriseAttachmentController
      private

      def attachment_name
        :terms_and_conditions
      end

      def enterprise_authorize_action
        case action_name.to_sym
        when :destroy
          :remove_terms_and_conditions
        end
      end
    end
  end
end
