module Api
  class EnterprisesController < Spree::Api::BaseController
    respond_to :json

    def managed
      @enterprises = Enterprise.ransack(params[:q]).result.managed_by(current_api_user)
      render params[:template] || :bulk_index
    end
  end
end
