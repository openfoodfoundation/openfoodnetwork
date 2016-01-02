module Admin
  class CustomersController < ResourceController
    before_action :load_managed_shops, only: :index, if: :html_request?
    respond_to :json

    def index
      respond_to do |format|
        format.html
        format.json do
          render json: ActiveModel::ArraySerializer.new(@collection,
                                                        each_serializer: Api::Admin::CustomerSerializer, spree_current_user: spree_current_user
                                                       ).to_json
        end
      end
    end

    private

    def collection
      return Customer.where('1=0') unless json_request? && params[:enterprise_id].present?
      enterprise = Enterprise.managed_by(spree_current_user).find_by_id(params[:enterprise_id])
      Customer.of(enterprise)
    end

    def load_managed_shops
      @shops = Enterprise.managed_by(spree_current_user).is_distributor
    end
  end
end
