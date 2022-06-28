# frozen_string_literal: true

module Api
  module V0
    class SmallFarmerRecognitionDocumentsController < Api::V0::EnterpriseAttachmentController
      private

      def attachment_name
        :small_farmer_recognition_document
      end

      def enterprise_authorize_action
        case action_name.to_sym
        when :destroy
          :remove_small_farmer_recognition_document
        end
      end
    end
  end
end
