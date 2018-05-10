require 'open_food_network/address_finder'

module Admin
  class CustomersController < ResourceController
    before_filter :load_managed_shops, only: :index, if: :html_request?
    respond_to :json

    respond_override update: { json: {
      success: lambda {
        tag_rule_mapping = TagRule.mapping_for(Enterprise.where(id: @customer.enterprise))
        render_as_json @customer, tag_rule_mapping: tag_rule_mapping
      },
      failure: lambda { render json: { errors: @customer.errors.full_messages }, status: :unprocessable_entity }
    } }

    def index
      respond_to do |format|
        format.html
        format.json do
          tag_rule_mapping = TagRule.mapping_for(Enterprise.where(id: params[:enterprise_id]))
          render_as_json @collection, tag_rule_mapping: tag_rule_mapping
        end
      end
    end

    def show
      render_as_json @customer, ams_prefix: params[:ams_prefix]
    end

    def create
      @customer = Customer.new(params[:customer])
      if user_can_create_customer?
        if @customer.save
          tag_rule_mapping = TagRule.mapping_for(Enterprise.where(id: @customer.enterprise))
          render_as_json @customer, tag_rule_mapping: tag_rule_mapping
        else
          render json: { errors: @customer.errors.full_messages }, status: 400
        end
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
          format.json { render json: { errors: @object.errors.full_messages }, status: :conflict }
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

    def ams_prefix_whitelist
      [:subscription]
    end
  end
end
