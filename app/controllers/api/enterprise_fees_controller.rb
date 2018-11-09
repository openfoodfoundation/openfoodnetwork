module Api
  class EnterpriseFeesController < BaseController
    respond_to :json

    def destroy
      authorize! :destroy, @enterprise_fee

      if enterprise_fee.destroy
        render text: I18n.t(:successfully_removed), status: 204
      else
        render json: { errors: enterprise_fee.errors }, status: 403
      end
    end

    private

    def enterprise_fee
      @enterprise_fee ||= EnterpriseFee.find_by_id params[:id]
    end
  end
end
