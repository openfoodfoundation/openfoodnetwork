# frozen_string_literal: true

module Spree
  module Admin
    class ProductPropertiesController < ::Admin::ResourceController
      belongs_to 'spree/product'
      before_action :find_properties
      before_action :setup_property, only: [:index]

      def index
        @url_filters = ::ProductFilters.new.extract(request.query_parameters)
      end

      def destroy
        @url_filters = ::ProductFilters.new.extract(request.query_parameters)

        if @object.destroy
          flash[:success] = flash_message_for(@object, :successfully_removed)
        end
        # if destroy fails it won't show any errors to the user
        redirect_to spree.admin_product_product_properties_url(params[:product_id], @url_filters)
      end

      private

      def find_properties
        @properties = Spree::Property.pluck(:name)
      end

      def setup_property
        @product.product_properties.build
      end
    end
  end
end
