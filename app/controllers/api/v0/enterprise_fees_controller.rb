# frozen_string_literal: true

module Api
  module V0
    class EnterpriseFeesController < Api::V0::BaseController
      respond_to :json

      def destroy
        authorize! :destroy, enterprise_fee

        if enterprise_fee.destroy
          render plain: I18n.t(:successfully_removed), status: :no_content
        else
          render plain: enterprise_fee.errors.full_messages.first, status: :forbidden
        end
      end

      private

      def enterprise_fee
        @enterprise_fee ||= EnterpriseFee.find_by id: params[:id]
      end
    end
  end
end
