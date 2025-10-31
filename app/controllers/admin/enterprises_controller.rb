# frozen_string_literal: true

require 'open_food_network/referer_parser'
require 'open_food_network/permissions'
require 'open_food_network/order_cycle_permissions'

module Admin
  class EnterprisesController < Admin::ResourceController
    include GeocodeEnterpriseAddress
    include CablecarResponses
    include Pagy::Backend

    # These need to run before #load_resource so that @object is initialised with sanitised values
    prepend_before_action :override_owner, only: :create
    prepend_before_action :override_sells, only: :create

    before_action :load_countries, except: [:index, :register]
    before_action :require_enterprise, only: [:edit, :update]
    before_action :load_methods_and_fees, only: [:edit, :update]
    before_action :load_groups, only: [:new, :edit, :update, :create]
    before_action :load_taxons, only: [:new, :edit, :update, :create]
    before_action :check_can_change_sells, only: :update
    before_action :check_can_change_bulk_sells, only: :bulk_update
    before_action :check_can_change_owner, only: :update
    before_action :check_can_change_bulk_owner, only: :bulk_update
    before_action :check_can_change_managers, only: :update
    before_action :strip_new_properties, only: [:create, :update]
    before_action :load_properties, only: [:edit, :update]
    before_action :setup_property, only: [:edit]

    after_action  :geocode_address_if_use_geocoder, only: [:create, :update]

    include OrderCyclesHelper

    def index
      load_enterprise_set_on_index

      respond_to do |format|
        format.html
        format.json {
          render_as_json @collection, ams_prefix: params[:ams_prefix],
                                      spree_current_user:
        }
      end
    end

    def edit
      @object = Enterprise.where(permalink: params[:id]).
        includes(users: [:ship_address, :bill_address]).first
      @object.build_custom_tab if @object.custom_tab.nil?

      load_tag_rule_types

      return unless params[:stimulus]

      @enterprise.is_primary_producer = params[:is_primary_producer]
      @enterprise.sells = params[:enterprise_sells]
      render cable_ready: cable_car.morph("#side_menu", partial("admin/shared/side_menu"))
        .morph("#permalink", partial("admin/enterprises/form/permalink"))
    end

    def welcome
      render layout: "spree/layouts/bare_admin"
    end

    def update
      tag_rules_attributes = params[object_name].delete :tag_rules_attributes
      update_tag_rules(tag_rules_attributes) if tag_rules_attributes.present?
      update_enterprise_notifications
      update_vouchers

      delete_custom_tab if params[:custom_tab] == 'false'

      if @object.update(enterprise_params)
        flash[:success] = flash_success_message

        respond_with(@object) do |format|
          format.html { redirect_to location_after_save }
          format.js   { render layout: false }
          format.json {
            render_as_json @object, ams_prefix: 'index', spree_current_user:
          }
          format.turbo_stream
        end
      else
        load_tag_rule_types
        respond_with(@object) do |format|
          format.json {
            render json: { errors: @object.errors.messages }, status: :unprocessable_entity
          }
        end
      end
    end

    def register
      register_params = params.permit(:sells)

      if register_params[:sells] == 'unspecified'
        flash[:error] = I18n.t(:enterprise_register_package_error)
        return render :welcome, layout: "spree/layouts/bare_admin"
      end

      attributes = { sells: register_params[:sells], visible: "only_through_links" }

      if @enterprise.update(attributes)
        flash[:success] = I18n.t(:enterprise_register_success_notice, enterprise: @enterprise.name)
        redirect_to spree.admin_dashboard_path
      else
        flash[:error] = I18n.t(:enterprise_register_error, enterprise: @enterprise.name)
        render :welcome, layout: "spree/layouts/bare_admin"
      end
    end

    def bulk_update
      load_enterprise_set_with_params(bulk_params)

      if @enterprise_set.save
        flash[:success] = I18n.t(:enterprise_bulk_update_success_notice)

        redirect_to main_app.admin_enterprises_path
      else
        touched_enterprises = @enterprise_set.collection.select(&:changed?)
        @enterprise_set.collection.to_a.select! { |e| touched_enterprises.include? e }
        flash[:error] = I18n.t(:enterprise_bulk_update_error)
        render :index
      end
    end

    def for_order_cycle
      respond_to do |format|
        format.json do
          render(
            json: @collection,
            each_serializer: Api::Admin::ForOrderCycle::EnterpriseSerializer,
            order_cycle: @order_cycle,
            spree_current_user:
          )
        end
      end
    end

    def visible
      respond_to do |format|
        format.json do
          render_as_json @collection, ams_prefix: params[:ams_prefix] || 'basic',
                                      spree_current_user:
        end
      end
    end

    def new_tag_rule_group
      load_tag_rule_types

      @index = params[:index]
      @customer_rule_index = params[:customer_rule_index].to_i
      @group = { tags: [], rules: [] }

      respond_to do |format|
        format.turbo_stream
      end
    end

    def destroy
      @index = params[:index]

      if @object.destroy
        flash.now[:success] = Spree.t(:successfully_removed, resource: "Enterprise")
      else
        flash.now[:error] = @object.errors.full_messages.to_sentence
      end

      respond_to do |format|
        format.turbo_stream { render :destroy, status: :ok }
      end
    end

    protected

    def delete_custom_tab
      @object.custom_tab.destroy if @object.custom_tab.present?
      enterprise_params.delete(:custom_tab_attributes)
    end

    def build_resource
      enterprise = super
      enterprise.address ||= Spree::Address.new
      enterprise.address.country ||= DefaultCountry.country
      enterprise
    end

    # Overriding method on Spree's resource controller,
    # so that resources are found using permalink
    def find_resource
      Enterprise.find_by(permalink: params[:id])
    end

    private

    def flash_success_message
      if attachment_removal?
        I18n.t("admin.controllers.enterprises.#{attachment_removal_parameter}_success")
      else
        flash_message_for(@object, :successfully_updated)
      end
    end

    def attachment_removal?
      attachment_removal_parameter.present?
    end

    def attachment_removal_parameter
      if enterprise_params.keys.one? && enterprise_params.keys.first.to_s.start_with?("remove_")
        enterprise_params.keys.first
      end
    end
    helper_method :attachment_removal_parameter

    def load_enterprise_set_on_index
      return unless spree_current_user.admin?

      load_enterprise_set_with_params
    end

    def load_enterprise_set_with_params(params = {})
      @pagy, @paginated_collection = pagy(@collection)
      @enterprise_set = Sets::EnterpriseSet.new(@paginated_collection, params)
    end

    def load_countries
      @countries = Spree::Country.order(:name)
    end

    def collection
      case action
      when :for_order_cycle
        @order_cycle = OrderCycle.find_by(id: params[:order_cycle_id]) if params[:order_cycle_id]
        coordinator = Enterprise.find_by(id: params[:coordinator_id]) if params[:coordinator_id]
        @order_cycle ||= OrderCycle.new(coordinator:) if coordinator.present?

        enterprises = OpenFoodNetwork::OrderCyclePermissions.new(spree_current_user, @order_cycle)
          .visible_enterprises

        if enterprises.present?
          enterprises.includes(supplied_products: [:variants, :image])
        end
      when :index
        if spree_current_user.admin?
          OpenFoodNetwork::Permissions.new(spree_current_user).
            editable_enterprises.
            order('is_primary_producer ASC, name')
        elsif json_request?
          OpenFoodNetwork::Permissions.new(spree_current_user)
            .editable_enterprises.ransack(params[:q]).result
        else
          Enterprise.where("1=0")
        end
      when :visible
        OpenFoodNetwork::Permissions.new(spree_current_user).visible_enterprises
          .includes(:shipping_methods, :payment_methods).ransack(params[:q]).result
      else
        OpenFoodNetwork::Permissions.new(spree_current_user).
          editable_enterprises.
          order('is_primary_producer ASC, name')
      end
    end

    def collection_actions
      [:index, :for_order_cycle, :visible, :bulk_update]
    end

    def require_enterprise
      raise ActiveRecord::RecordNotFound if @enterprise.blank?
    end

    def load_methods_and_fees
      enterprise_payment_methods = @enterprise.payment_methods.to_a
      enterprise_shipping_methods = @enterprise.shipping_methods.to_a
      # rubocop:disable Style/TernaryParentheses
      @payment_methods = Spree::PaymentMethod.managed_by(spree_current_user).to_a.sort_by! do |pm|
        [(enterprise_payment_methods.include? pm) ? 0 : 1, pm.name]
      end
      @shipping_methods = Spree::ShippingMethod.managed_by(spree_current_user).to_a.sort_by! do |sm|
        [(enterprise_shipping_methods.include? sm) ? 0 : 1, sm.name]
      end
      # rubocop:enable Style/TernaryParentheses

      @enterprise_fees = EnterpriseFee
        .managed_by(spree_current_user)
        .for_enterprise(@enterprise)
        .order(:fee_type, :name)
        .all
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
        tag_rules_attributes.select{ |_i, attrs| attrs[:type].present? }.each_value do |attrs|
          rule = @object.tag_rules.find_by(id: attrs.delete(:id)) ||
                 attrs[:type].constantize.new(enterprise: @object)

          rule.update(attrs.permit(PermittedAttributes::TagRules.attributes))
        end
      end
    end

    def update_enterprise_notifications
      user_id = params[:receives_notifications].to_i

      return unless user_id.positive? && @enterprise.user_ids.include?(user_id)

      @enterprise.update_contact(user_id)
    end

    def update_vouchers
      params_voucher_ids = params[:enterprise][:voucher_ids].to_a.map(&:to_i)
      voucher_ids = @enterprise.vouchers.map(&:id)
      deleted_voucher_ids = @enterprise.vouchers.only_deleted.map(&:id)

      vouchers_to_destroy = voucher_ids - params_voucher_ids
      Voucher.where(id: vouchers_to_destroy).destroy_all if vouchers_to_destroy.present?

      vouchers_to_restore = deleted_voucher_ids.intersection(params_voucher_ids)
      Voucher.restore(vouchers_to_restore) if vouchers_to_restore.present?
    end

    def create_calculator_for(rule, attrs)
      return unless attrs[:calculator_type].present? && attrs[:calculator_attributes].present?

      rule.update(calculator_type: attrs[:calculator_type])
      attrs[:calculator_attributes].merge!( id: rule.calculator.id )
    end

    def check_can_change_bulk_sells
      return if spree_current_user.admin?

      params[:sets_enterprise_set][:collection_attributes].each_value do |enterprise_params|
        unless spree_current_user == Enterprise.find_by(id: enterprise_params[:id]).owner
          enterprise_params.delete :sells
        end
      end
    end

    def check_can_change_sells
      return if spree_current_user.admin? || spree_current_user == @enterprise.owner

      enterprise_params.delete :sells
    end

    def override_owner
      enterprise_params[:owner_id] = spree_current_user.id unless spree_current_user.admin?
    end

    def override_sells
      return if spree_current_user.admin?

      has_hub = spree_current_user.owned_enterprises.is_hub.any?
      new_enterprise_is_producer = Enterprise.new(enterprise_params).is_primary_producer
      enterprise_params[:sells] = has_hub && !new_enterprise_is_producer ? 'any' : 'none'
    end

    def check_can_change_owner
      return if ( spree_current_user == @enterprise.owner ) || spree_current_user.admin?

      enterprise_params.delete :owner_id
    end

    def check_can_change_bulk_owner
      return if spree_current_user.admin?

      bulk_params[:collection_attributes].each_value do |enterprise_params|
        enterprise_params.delete :owner_id
      end
    end

    def check_can_change_managers
      return if ( spree_current_user == @enterprise.owner ) || spree_current_user.admin?

      enterprise_params.delete :user_ids
    end

    def strip_new_properties
      unless spree_current_user.admin? || params.dig(:enterprise,
                                                     :producer_properties_attributes).nil?
        names = Spree::Property.pluck(:name)
        enterprise_params[:producer_properties_attributes].each do |key, property|
          unless names.include? property[:property_name]
            enterprise_params[:producer_properties_attributes].delete key
          end
        end
      end
    end

    def load_properties
      @properties = Spree::Property.pluck(:name)
    end

    def load_tag_rule_types
      @tag_rule_types = [
        [t(".form.tag_rules.show_hide_shipping"), "FilterShippingMethods"],
        [t(".form.tag_rules.show_hide_payment"), "FilterPaymentMethods"],
        [t(".form.tag_rules.show_hide_order_cycles"), "FilterOrderCycles"]
      ]

      return unless helpers.feature?(:inventory, @object)

      @tag_rule_types.prepend([t(".form.tag_rules.show_hide_variants"), "FilterProducts"])
    end

    def setup_property
      @enterprise.producer_properties.build
    end

    # Overriding method on Spree's resource controller
    def location_after_save
      referer_path = OpenFoodNetwork::RefererParser.path(request.referer)
      # rubocop:disable Style/RegexpLiteral
      refered_from_producer_properties = referer_path =~ /\/producer_properties$/
      # rubocop:enable Style/RegexpLiteral

      if refered_from_producer_properties
        main_app.admin_enterprise_producer_properties_path(@enterprise)
      else
        main_app.edit_admin_enterprise_path(@enterprise)
      end
    end

    def ams_prefix_whitelist
      [:index, :basic]
    end

    def enterprise_params
      @enterprise_params ||= PermittedAttributes::Enterprise.new(params).call.
        to_h.with_indifferent_access
    end

    def bulk_params
      @bulk_params ||= params.require(:sets_enterprise_set).permit(
        collection_attributes: PermittedAttributes::Enterprise.attributes
      ).to_h.with_indifferent_access
    end

    # Used in Admin::ResourceController#create
    def permitted_resource_params
      enterprise_params
    end
  end
end
