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
          render_as_json @collection,
                         tag_rule_mapping: tag_rule_mapping,
                         customer_tags: customer_tags_by_id
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
          render json: { errors: @customer.errors.full_messages }, status: :bad_request
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

      Customer.of(managed_enterprise_id).
        includes(:bill_address, :ship_address, user: :credit_cards)
    end

    def managed_enterprise_id
      @managed_enterprise_id ||= Enterprise.managed_by(spree_current_user).
        select('enterprises.id').find_by_id(params[:enterprise_id])
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

    def tag_rule_mapping
      TagRule.mapping_for(Enterprise.where(id: managed_enterprise_id))
    end

    # Fetches tags for all customers of the enterprise and returns a hash indexed by customer_id
    def customer_tags_by_id
      customer_tags = ::ActsAsTaggableOn::Tag.
        joins(:taggings).
        includes(:taggings).
        where(taggings:
                { taggable_type: 'Customer',
                  taggable_id: Customer.of(managed_enterprise_id),
                  context: 'tags' })

      customer_tags.each_with_object({}) do |tag, indexed_hash|
        customer_id = tag.taggings.first.taggable_id
        indexed_hash[customer_id] ||= []
        indexed_hash[customer_id] << tag.name
      end
    end
  end
end
