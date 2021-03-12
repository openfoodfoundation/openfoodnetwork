module Api
  class EnterpriseFeesController < Api::BaseController
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
