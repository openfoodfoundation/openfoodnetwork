# frozen_string_literal: true

module Spree
  module Admin
    class ImagesController < ::Admin::ResourceController
      # This will make resource controller redirect correctly after deleting product images.
      # This can be removed after upgrading to Spree 2.1.
      # See here https://github.com/spree/spree/commit/334a011d2b8e16355e4ae77ae07cd93f7cbc8fd1
      belongs_to 'spree/product'

      before_action :load_data

      def index
        @url_filters = ::ProductFilters.new.extract(request.query_parameters)
      end

      def new
        @url_filters = ::ProductFilters.new.extract(request.query_parameters)

        render layout: !request.xhr?
      end

      def edit
        @url_filters = ::ProductFilters.new.extract(request.query_parameters)
      end

      def create
        @url_filters = ::ProductFilters.new.extract(request.query_parameters)
        set_viewable

        @object.attributes = permitted_resource_params

        if @object.save
          flash[:success] = flash_message_for(@object, :successfully_created)
          redirect_to spree.admin_product_images_url(params[:product_id], @url_filters)
        else
          respond_with(@object)
        end
      end

      def update
        @url_filters = ::ProductFilters.new.extract(request.query_parameters)
        set_viewable

        if @object.update(permitted_resource_params)
          flash[:success] = flash_message_for(@object, :successfully_updated)
          redirect_to spree.admin_product_images_url(params[:product_id], @url_filters)
        else
          respond_with(@object)
        end
      end

      def destroy
        @url_filters = ::ProductFilters.new.extract(request.query_parameters)
        destroy_before

        if @object.destroy
          flash[:success] = flash_message_for(@object, :successfully_removed)
        end

        redirect_to spree.admin_product_images_url(params[:product_id], @url_filters)
      end

      private

      def collection
        parent.image
      end

      def find_resource
        parent.image
      end

      def build_resource
        Spree::Image.new(viewable: parent)
      end

      def location_after_save
        spree.admin_product_images_url(@product)
      end

      def load_data
        @product = Product.find(params[:product_id])
      end

      def set_viewable
        @image.viewable_type = 'Spree::Product'
        @image.viewable_id = params[:image][:viewable_id]
      end

      def destroy_before
        @viewable = @image.viewable
      end

      def permitted_resource_params
        params.require(:image).permit(
          :attachment, :viewable_id, :alt
        )
      end
    end
  end
end
