# frozen_string_literal: true

module Api
  module V0
    class LogosController < Api::V0::EnterpriseAttachmentController
      private

      def attachment_name
        :logo
      end

      def enterprise_authorize_action
        case action_name.to_sym
        when :destroy
          :remove_logo
        end
      end
    end
  end
end
