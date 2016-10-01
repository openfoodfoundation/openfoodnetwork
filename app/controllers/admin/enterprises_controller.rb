require 'open_food_network/referer_parser'

module Admin
  class EnterprisesController < ResourceController
    # These need to run before #load_resource so that @object is initialised with sanitised values
    prepend_before_filter :override_owner, only: :create
    prepend_before_filter :override_sells, only: :create

    before_filter :load_enterprise_set, :only => :index
    before_filter :load_countries, :except => [:index, :register, :check_permalink]
    before_filter :load_methods_and_fees, :only => [:edit, :update]
    before_filter :load_groups, :only => [:new, :edit, :update, :create]
    before_filter :load_taxons, :only => [:new, :edit, :update, :create]
    before_filter :check_can_change_sells, only: :update
    before_filter :check_can_change_bulk_sells, only: :bulk_update
    before_filter :check_can_change_owner, only: :update
    before_filter :check_can_change_bulk_owner, only: :bulk_update
    before_filter :check_can_change_managers, only: :update
    before_filter :strip_new_properties, only: [:create, :update]
    before_filter :load_properties, only: [:edit, :update]
    before_filter :setup_property, only: [:edit]

    helper 'spree/products'
    include ActionView::Helpers::TextHelper
    include OrderCyclesHelper
    include Admin::StripeHelper

    def index
      respond_to do |format|
        format.html
        format.json { render_as_json @collection, ams_prefix: params[:ams_prefix], spree_current_user: spree_current_user }
      end
    end

    def welcome
      render layout: "spree/layouts/bare_admin"
    end

    def update
      invoke_callbacks(:update, :before)
      tag_rules_attributes = params[object_name].delete :tag_rules_attributes
      update_tag_rules(tag_rules_attributes) if tag_rules_attributes.present?
      if @object.update_attributes(params[object_name])
        invoke_callbacks(:update, :after)
        flash[:success] = flash_message_for(@object, :successfully_updated)
        respond_with(@object) do |format|
          format.html { redirect_to location_after_save }
          format.js   { render :layout => false }
          format.json { render_as_json @object, ams_prefix: 'index', spree_current_user: spree_current_user }
        end
      else
        invoke_callbacks(:update, :fails)
        respond_with(@object) do |format|
          format.json { render json: { errors: @object.errors.messages }, status: :unprocessable_entity }
        end
      end
    end

    def register
      if params[:sells] == 'unspecified'
        flash[:error] = "Please select a package"
        return render :welcome, layout: "spree/layouts/bare_admin"
      end

      attributes = { sells: params[:sells], visible: true }

      if ['own', 'any'].include? params[:sells]
        attributes[:shop_trial_start_date] = @enterprise.shop_trial_start_date || Time.zone.now
      end

      if @enterprise.update_attributes(attributes)
        flash[:success] = "Congratulations! Registration for #{@enterprise.name} is complete!"
        redirect_to admin_path
      else
        flash[:error] = "Could not complete registration for #{@enterprise.name}"
        render :welcome, layout: "spree/layouts/bare_admin"
      end
    end

    def bulk_update
      @enterprise_set = EnterpriseSet.new(collection, params[:enterprise_set])
      touched_enterprises = @enterprise_set.collection.select(&:changed?)
      if @enterprise_set.save
        flash[:success] = "Enterprises updated successfully"

        # 18-3-2015: It seems that the form for this action sometimes loads bogus values for
        # the 'sells' field, and submitting that form results in a bunch of enterprises with
        # values that have mysteriously changed. This statement is here to help debug that
        # issue, and should be removed (along with its display in index.html.haml) when the
        # issue has been resolved.
        flash[:action] = "Updated #{pluralize(touched_enterprises.count, 'enterprise')}: #{touched_enterprises.map(&:name).join(', ')}"

        redirect_to main_app.admin_enterprises_path
      else
        @enterprise_set.collection.select! { |e| touched_enterprises.include? e }
        flash[:error] = 'Update failed'
        render :index
      end
    end

    def for_order_cycle
      respond_to do |format|
        format.json do
          render json: @collection, each_serializer: Api::Admin::ForOrderCycle::EnterpriseSerializer, order_cycle: @order_cycle, spree_current_user: spree_current_user
        end
      end
    end

    def for_line_items
      respond_to do |format|
        format.json do
          render_as_json @collection, ams_prefix: 'basic', spree_current_user: spree_current_user
        end
      end
    end

    def stripe_connect
      redirect_to authorize_stripe(params[:enterprise_id])
    end

    def stripe_connect_callback
      if params["code"]
        state = JSON.parse(params["state"].gsub("=>",":"))
        # Get the Enterprise
        @enterprise = Enterprise.find_by_permalink(state["enterprise_id"])

        # Get the deets from Stripe
        response_params = get_stripe_token(params["code"]).params

        stripe_account = StripeAccount.new(stripe_user_id: response_params["stripe_user_id"], stripe_publishable_key: response_params["stripe_publishable_key"], enterprise: @enterprise)
        if stripe_account.save
          respond_to do |format|
            format.html { redirect_to main_app.edit_admin_enterprise_path(@enterprise), notice: "Stripe account connected successfully."}
            format.json { render json: stripe_account }
          end
        else
          render text: "Failed to save Stripe token", status: 500
        end
      else
        render text: params["error_description"], status: 500
      end
    end

    def stripe_disconnect
      if deauthorize_stripe(params[:account_id])
        respond_to do |format|
          format.html { redirect_to main_app.edit_admin_enterprise_path(@enterprise), notice: "Stripe account disconnected."}
          format.json { render json: "Disconnected" }
        end
      end
    end

    protected

    def build_resource_with_address
      enterprise = build_resource_without_address
      enterprise.address ||= Spree::Address.new
      enterprise.address.country ||= Spree::Country.find_by_id(Spree::Config[:default_country_id])
      enterprise
    end
    alias_method_chain :build_resource, :address

    # Overriding method on Spree's resource controller,
    # so that resources are found using permalink
    def find_resource
      Enterprise.find_by_permalink(params[:id])
    end

    private

    def load_enterprise_set
      @enterprise_set = EnterpriseSet.new(collection) if spree_current_user.admin?
    end

    def load_countries
      @countries = Spree::Country.order(:name)
    end

    def collection
      case action
      when :for_order_cycle
        @order_cycle = OrderCycle.find_by_id(params[:order_cycle_id]) if params[:order_cycle_id]
        coordinator = Enterprise.find_by_id(params[:coordinator_id]) if params[:coordinator_id]
        @order_cycle = OrderCycle.new(coordinator: coordinator) if @order_cycle.nil? && coordinator.present?
        return OpenFoodNetwork::OrderCyclePermissions.new(spree_current_user, @order_cycle).visible_enterprises
      when :index
        if spree_current_user.admin?
          OpenFoodNetwork::Permissions.new(spree_current_user).
            editable_enterprises.
            order('is_primary_producer ASC, name')
        elsif json_request?
          OpenFoodNetwork::Permissions.new(spree_current_user).editable_enterprises.ransack(params[:q]).result
        else
          Enterprise.where("1=0")
        end
      when :for_line_items
        OpenFoodNetwork::Permissions.new(spree_current_user).visible_enterprises.ransack(params[:q]).result
      else
        # TODO was ordered with is_distributor DESC as well, not sure why or how we want to sort this now
        OpenFoodNetwork::Permissions.new(spree_current_user).
          editable_enterprises.
          order('is_primary_producer ASC, name')
      end
    end

    def collection_actions
      [:index, :for_order_cycle, :for_line_items, :bulk_update]
    end

    def load_methods_and_fees
      @payment_methods = Spree::PaymentMethod.managed_by(spree_current_user).sort_by!{ |pm| [(@enterprise.payment_methods.include? pm) ? 0 : 1, pm.name] }
      @shipping_methods = Spree::ShippingMethod.managed_by(spree_current_user).sort_by!{ |sm| [(@enterprise.shipping_methods.include? sm) ? 0 : 1, sm.name] }
      @enterprise_fees = EnterpriseFee.managed_by(spree_current_user).for_enterprise(@enterprise).order(:fee_type, :name).all
    end

    def load_groups
      @groups = EnterpriseGroup.managed_by(spree_current_user) | @enterprise.groups
    end

    def load_taxons
      @taxons = Spree::Taxon.order(:name)
    end

    def update_tag_rules(tag_rules_attributes)
      # Due to the combination of trying to use nested attributes and type inheritance
      # we cannot apply all attributes to tag rules in one hit because mass assignment
      # methods that are specific to each class do not become available until after the
      # record is persisted. This problem is compounded by the use of calculators.
      @object.transaction do
        tag_rules_attributes.select{ |i, attrs| attrs[:type].present? }.each do |i, attrs|
          rule = @object.tag_rules.find_by_id(attrs.delete :id) || attrs[:type].constantize.new(enterprise:  @object)
          create_calculator_for(rule, attrs) if rule.type == "TagRule::DiscountOrder" && rule.calculator.nil?
          rule.update_attributes(attrs)
        end
      end
    end

    def create_calculator_for(rule, attrs)
      if attrs[:calculator_type].present? && attrs[:calculator_attributes].present?
        rule.update_attributes(calculator_type: attrs[:calculator_type])
        attrs[:calculator_attributes].merge!( { id: rule.calculator.id } )
      end
    end

    def check_can_change_bulk_sells
      unless spree_current_user.admin?
        params[:enterprise_set][:collection_attributes].each do |i, enterprise_params|
          enterprise_params.delete :sells unless spree_current_user == Enterprise.find_by_id(enterprise_params[:id]).owner
        end
      end
    end

    def check_can_change_sells
      unless spree_current_user.admin? || spree_current_user == @enterprise.owner
        params[:enterprise].delete :sells
      end
    end

    def override_owner
      params[:enterprise][:owner_id] = spree_current_user.id unless spree_current_user.admin?
    end

    def override_sells
      unless spree_current_user.admin?
        has_hub = spree_current_user.owned_enterprises.is_hub.any?
        new_enterprise_is_producer = Enterprise.new(params[:enterprise]).is_primary_producer
        params[:enterprise][:sells] = (has_hub && !new_enterprise_is_producer) ? 'any' : 'none'
      end
    end

    def check_can_change_owner
      unless ( spree_current_user == @enterprise.owner ) || spree_current_user.admin?
        params[:enterprise].delete :owner_id
      end
    end

    def check_can_change_bulk_owner
      unless spree_current_user.admin?
        params[:enterprise_set][:collection_attributes].each do |i, enterprise_params|
          enterprise_params.delete :owner_id
        end
      end
    end

    def check_can_change_managers
      unless ( spree_current_user == @enterprise.owner ) || spree_current_user.admin?
        params[:enterprise].delete :user_ids
      end
    end

    def strip_new_properties
      unless spree_current_user.admin? || params[:enterprise][:producer_properties_attributes].nil?
        names = Spree::Property.pluck(:name)
        params[:enterprise][:producer_properties_attributes].each do |key, property|
          params[:enterprise][:producer_properties_attributes].delete key unless names.include? property[:property_name]
        end
      end
    end

    def load_properties
      @properties = Spree::Property.pluck(:name)
    end

    def setup_property
      @enterprise.producer_properties.build
    end

    # Overriding method on Spree's resource controller
    def location_after_save
      referer_path = OpenFoodNetwork::RefererParser::path(request.referer)
      refered_from_producer_properties = referer_path =~ /\/producer_properties$/

      if refered_from_producer_properties
        main_app.admin_enterprise_producer_properties_path(@enterprise)
      else
        main_app.edit_admin_enterprise_path(@enterprise)
      end
    end

    def ams_prefix_whitelist
      [:index, :basic]
    end
  end
end
