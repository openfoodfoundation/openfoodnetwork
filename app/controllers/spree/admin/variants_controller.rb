# frozen_string_literal: true

require 'open_food_network/scope_variants_for_search'

module Spree
  module Admin
    class VariantsController < ::Admin::ResourceController
      belongs_to 'spree/product'

      before_action :load_data, only: [:new, :edit]

      def index
        @url_filters = ::ProductFilters.new.extract(request.query_parameters)
      end

      def new
        @url_filters = ::ProductFilters.new.extract(request.query_parameters)
      end

      def edit
        @url_filters = ::ProductFilters.new.extract(request.query_parameters)
      end

      def create
        @url_filters = ::ProductFilters.new.extract(request.query_parameters)

        on_demand = params[:variant].delete(:on_demand)
        on_hand = params[:variant].delete(:on_hand)

        @object.attributes = permitted_resource_params
        if @object.save
          flash[:success] = flash_message_for(@object, :successfully_created)
          redirect_to spree.admin_product_variants_url(params[:product_id], @url_filters)
        else
          flash[:error] = @object.errors.full_messages.to_sentence if @object.errors.any?
          redirect_to spree.new_admin_product_variant_url(params[:product_id], @url_filters)
        end

        return unless @object.present? && @object.valid?

        @object.on_demand = on_demand if on_demand.present?
        @object.on_hand = on_hand.to_i if on_hand.present?
      end

      def update
        @url_filters = ::ProductFilters.new.extract(request.query_parameters)

        if @object.update(permitted_resource_params)
          flash[:success] = flash_message_for(@object, :successfully_updated)
          redirect_to spree.admin_product_variants_url(params[:product_id], @url_filters)
        else
          redirect_to spree.edit_admin_product_variant_url(params[:product_id],
                                                           @object,
                                                           @url_filters)
        end
      end

      def search
        scoper = OpenFoodNetwork::ScopeVariantsForSearch.new(variant_search_params)
        @variants = scoper.search
        render json: @variants, each_serializer: ::Api::Admin::VariantSerializer
      end

      def destroy
        @url_filters = ::ProductFilters.new.extract(request.query_parameters)

        @variant = Spree::Variant.find(params[:id])
        flash[:success] = delete_variant

        redirect_to spree.admin_product_variants_url(params[:product_id], @url_filters)
      end

      protected

      def delete_variant
        if VariantDeleter.new.delete(@variant)
          Spree.t('notice_messages.variant_deleted')
        else
          Spree.t('notice_messages.variant_not_deleted')
        end
      end

      def create_before
        @object.save
      end

      def collection
        @deleted = params.key?(:deleted) && params[:deleted] == "on" ? "checked" : ""

        @collection ||= if @deleted.blank?
                          super
                        else
                          Variant.unscoped.where(product_id: parent.id).deleted
                        end
        @collection
      end

      def variant_params
        params.require(:variant).permit(::PermittedAttributes::Variant.attributes)
      end

      def permitted_resource_params
        variant_params
      end

      def variant_search_params
        params.permit(
          :q, :distributor_id, :order_cycle_id, :schedule_id, :eligible_for_subscriptions,
          :include_out_of_stock
        ).to_h.with_indifferent_access
      end

      private

      def load_data
        @tax_categories = TaxCategory.order(:name)
      end
    end
  end
end
