# frozen_string_literal: true

module Spree
  module Admin
    class ShippingMethodsController < ::Admin::ResourceController
      before_action :load_data, except: [:index]
      before_action :set_shipping_category, only: [:create, :update]
      before_action :set_zones, only: [:create, :update]
      before_action :load_hubs, only: [:new, :edit, :create, :update]
      before_action :check_shipping_fee_input, only: [:update]

      # Sort shipping methods by distributor name
      def collection
        collection = super
        collection = collection.managed_by(spree_current_user).by_name

        if params.key? :enterprise_id
          distributor = Enterprise.find params[:enterprise_id]
          collection = collection.for_distributor(distributor)
        end

        collection
      end

      def new
        @object.shipping_categories = [DefaultShippingCategory.find_or_create]
        super
      end

      def destroy
        # Our reports are not adapted to soft deleted shipping_methods so here we prevent
        #   the deletion (even soft) of shipping_methods that are referenced in orders
        if order = order_referenced_by_shipping_method
          flash[:error] = I18n.t(:shipping_method_destroy_error, number: order.number)
          redirect_to(collection_url) && return
        end

        @object.touch :deleted_at
        flash[:success] = flash_message_for(@object, :successfully_removed)

        respond_with(@object) do |format|
          format.html { redirect_to collection_url }
        end
      end

      private

      def order_referenced_by_shipping_method
        Order.joins(shipments: :shipping_rates)
          .where( spree_shipping_rates: { shipping_method_id: @object } )
          .first
      end

      def load_hubs
        # rubocop:disable Style/TernaryParentheses
        @hubs = Enterprise.managed_by(spree_current_user).is_distributor.to_a.sort_by! do |d|
          [(@shipping_method.has_distributor? d) ? 0 : 1, d.name]
        end
        # rubocop:enable Style/TernaryParentheses
      end

      def set_shipping_category
        return true if params["shipping_method"][:shipping_categories] == ""

        @shipping_method.shipping_categories =
          Spree::ShippingCategory.where(id: params["shipping_method"][:shipping_categories])
        @shipping_method.save
        params[:shipping_method].delete(:shipping_categories)
      end

      def set_zones
        return true if params["shipping_method"][:zones] == ""

        @shipping_method.zones = Spree::Zone.where(id: params["shipping_method"][:zones])
        @shipping_method.save
        params[:shipping_method].delete(:zones)
      end

      def location_after_save
        spree.edit_admin_shipping_method_path(@shipping_method)
      end

      def load_data
        @available_zones = Zone.order(:name)
        @tax_categories = Spree::TaxCategory.order(:name)
        @calculators = ShippingMethod.calculators.sort_by(&:name)
      end

      def permitted_resource_params
        params.require(:shipping_method).permit(
          :name, :description, :display_on, :require_ship_address, :tag_list, :calculator_type,
          :tax_category_id, distributor_ids: [],
                            calculator_attributes: PermittedAttributes::Calculator.attributes
        )
      end

      def check_shipping_fee_input
        shipping_fees = permitted_resource_params['calculator_attributes']&.slice(
          :preferred_flat_percent, :preferred_amount,
          :preferred_first_item, :preferred_additional_item,
          :preferred_minimal_amount, :preferred_normal_amount,
          :preferred_discount_amount, :preferred_per_unit
        )

        return unless shipping_fees

        shipping_fees.each do |_, shipping_amount|
          unless shipping_amount.nil? || Float(shipping_amount, exception: false)
            flash[:error] = I18n.t(:calculator_preferred_value_error)
            return redirect_to location_after_save
          end
        end
      end
    end
  end
end
