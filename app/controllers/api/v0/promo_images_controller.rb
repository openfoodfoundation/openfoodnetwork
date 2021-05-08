# frozen_string_literal: true

module Api
  module V0
    class PromoImagesController < Api::V0::EnterpriseAttachmentController
      private

      def attachment_name
        :promo_image
      end

      def enterprise_authorize_action
        case action_name.to_sym
        when :destroy
          :remove_promo_image
        end
      end
    end
  end
end
