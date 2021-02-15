module Api
  module Legacy
    class PromoImagesController < Api::Legacy::EnterpriseAttachmentController
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
