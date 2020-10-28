module Spree
  module Admin
    class ImagesController < ResourceController
      # This will make resource controller redirect correctly after deleting product images.
      # This can be removed after upgrading to Spree 2.1.
      # See here https://github.com/spree/spree/commit/334a011d2b8e16355e4ae77ae07cd93f7cbc8fd1
      belongs_to 'spree/product', find_by: :permalink

      before_action :load_data

      def index
        @url_filters = ::ProductFilters.new.extract(request.query_parameters)
      end

      def new
        @url_filters = ::ProductFilters.new.extract(request.query_parameters)

        render layout: !request.xhr?
      end

      def create
        @url_filters = ::ProductFilters.new.extract(params)
        set_viewable

        @object.attributes = permitted_resource_params
        if @object.save
          flash[:success] = flash_message_for(@object, :successfully_created)
          redirect_to admin_product_images_url(params[:product_id], @url_filters)
        else
          respond_with(@object)
        end
      end

      def edit
        @url_filters = ::ProductFilters.new.extract(request.query_parameters)
      end

      def update
        @url_filters = ::ProductFilters.new.extract(params)
        set_viewable

        if @object.update(permitted_resource_params)
          flash[:success] = flash_message_for(@object, :successfully_updated)
          redirect_to admin_product_images_url(params[:product_id], @url_filters)
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

        redirect_to admin_product_images_url(params[:product_id], @url_filters)
      end

      private

      def location_after_save
        spree.admin_product_images_url(@product)
      end

      def load_data
        @product = Product.find_by(permalink: params[:product_id])
        @variants = @product.variants.collect do |variant|
          [variant.options_text, variant.id]
        end
        @variants.insert(0, [Spree.t(:all), @product.master.id])
      end

      def set_viewable
        @image.viewable_type = 'Spree::Variant'
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
