require 'open_food_network/address_finder'

module Admin
  class CustomersController < Admin::ResourceController
    before_action :load_managed_shops, only: :index, if: :html_request?
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
          render json: @collection,
                 each_serializer: index_each_serializer,
                 tag_rule_mapping: tag_rule_mapping,
                 customer_tags: customer_tags_by_id
        end
      end
    end

    def index_each_serializer
      if OpenFoodNetwork::FeatureToggle.enabled?(:customer_balance, spree_current_user)
        ::Api::Admin::CustomerWithBalanceSerializer
      else
        ::Api::Admin::CustomerWithCalculatedBalanceSerializer
      end
    end

    def show
      render_as_json @customer, ams_prefix: params[:ams_prefix]
    end

    def create
      @customer = Customer.new(customer_params)
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

    # copy of Admin::ResourceController without flash notice
    def destroy
      if @object.destroy
        respond_with(@object) do |format|
          format.html { redirect_to location_after_destroy }
          format.js   { render partial: "spree/admin/shared/destroy" }
        end
      else
        respond_with(@object) do |format|
          format.html { redirect_to location_after_destroy }
          format.json { render json: { errors: @object.errors.full_messages }, status: :conflict }
        end
      end
    end

    private

    def collection
      if json_request? && params[:enterprise_id].present?
        customers_relation.
          includes(:bill_address, :ship_address, user: :credit_cards)
      else
        Customer.where('1=0')
      end
    end

    def customers_relation
      if OpenFoodNetwork::FeatureToggle.enabled?(:customer_balance, spree_current_user)
        CustomersWithBalance.new(managed_enterprise_id).query
      else
        Customer.of(managed_enterprise_id)
      end
    end

    def managed_enterprise_id
      @managed_enterprise_id ||= Enterprise.managed_by(spree_current_user).
        select('enterprises.id').find_by(id: params[:enterprise_id])
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

    def customer_params
      params.require(:customer).permit(
        :enterprise_id, :name, :email, :code, :tag_list,
        ship_address_attributes: PermittedAttributes::Address.attributes,
        bill_address_attributes: PermittedAttributes::Address.attributes,
      )
    end

    # Used in Admin::ResourceController#update
    def permitted_resource_params
      customer_params
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
        tag.taggings.each do |tagging|
          customer_id = tagging.taggable_id
          indexed_hash[customer_id] ||= []
          indexed_hash[customer_id] << tag.name
        end
      end
    end
  end
end
