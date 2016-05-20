module Admin
  class CustomersController < ResourceController
    before_filter :load_managed_shops, only: :index, if: :html_request?
    respond_to :json

    def index
      respond_to do |format|
        format.html
        format.json do
          serialised = ActiveModel::ArraySerializer.new(
            @collection,
            each_serializer: Api::Admin::CustomerSerializer,
            spree_current_user: spree_current_user)
          render json: serialised.to_json
        end
      end
    end

    def create
      @customer = Customer.new(params[:customer])
      if user_can_create_customer?
        @customer.save
        render json: Api::Admin::CustomerSerializer.new(@customer).to_json
      else
        redirect_to '/unauthorized'
      end
    end

    # copy of Spree::Admin::ResourceController without flash notice
    def destroy
      invoke_callbacks(:destroy, :before)
      if @object.destroy
        invoke_callbacks(:destroy, :after)
        respond_with(@object) do |format|
          format.html { redirect_to location_after_destroy }
          format.js   { render partial: "spree/admin/shared/destroy" }
        end
      else
        invoke_callbacks(:destroy, :fails)
        respond_with(@object) do |format|
          format.html { redirect_to location_after_destroy }
        end
      end
    end

    private

    def collection
      return Customer.where("1=0") unless json_request? && params[:enterprise_id].present?
      enterprise = Enterprise.managed_by(spree_current_user).find_by_id(params[:enterprise_id])
      Customer.of(enterprise)
    end

    def load_managed_shops
      @shops = Enterprise.managed_by(spree_current_user).is_distributor
    end

    def user_can_create_customer?
      spree_current_user.admin? ||
        spree_current_user.enterprises.include?(@customer.enterprise)
    end
  end
end
