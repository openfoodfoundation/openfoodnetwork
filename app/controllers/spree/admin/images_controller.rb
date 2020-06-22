module Spree
  module Admin
    class ImagesController < ResourceController
      # This will make resource controller redirect correctly after deleting product images.
      # This can be removed after upgrading to Spree 2.1.
      # See here https://github.com/spree/spree/commit/334a011d2b8e16355e4ae77ae07cd93f7cbc8fd1
      belongs_to 'spree/product', find_by: :permalink

      before_action :load_data

      create.before :set_viewable
      update.before :set_viewable
      destroy.before :destroy_before

      private

      def location_after_save
        admin_product_images_url(@product)
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
