# frozen_string_literal: true

module Spree
  module Admin
    class ImagesController < ::Admin::ResourceController
      helper ::Admin::ProductsHelper

      # This will make resource controller redirect correctly after deleting product images.
      # This can be removed after upgrading to Spree 2.1.
      # See here https://github.com/spree/spree/commit/334a011d2b8e16355e4ae77ae07cd93f7cbc8fd1
      belongs_to 'spree/product'

      before_action :authorize_parent, only: [:create, :update]

      def new
        @url_filters = ::ProductFilters.new.extract(request.query_parameters)

        respond_to do |format|
          format.turbo_stream { render :edit }
          # There is no standalone HTML form for adding an image any more; the uploader
          # lives on the owner's edit page, so say why we're sending them back there.
          format.html {
            flash[:notice] = t('.use_uploader')
            redirect_to owner_edit_path
          }
        end
      end

      def edit
        @url_filters = ::ProductFilters.new.extract(request.query_parameters)
      end

      def create
        @url_filters = ::ProductFilters.new.extract(request.query_parameters)

        @object.attributes = permitted_resource_params
        # After the attributes, so a blank viewable_id in the body can't win over the
        # owner resolved from the URL.
        set_viewable
        set_default_caption unless params[:image].key?(:caption)

        return respond_with_error((@error_target || @object).errors) unless @object.save

        flash[:success] = flash_message_for(@object, :successfully_created)
        @redirect_url = location_after_save

        respond_to do |format|
          format.html { redirect_to @redirect_url }
          format.turbo_stream
        end
      end

      def update
        @url_filters = ::ProductFilters.new.extract(request.query_parameters)
        set_viewable

        if @object.update(permitted_resource_params)
          flash[:success] = flash_message_for(@object, :successfully_updated)

          respond_to do |format|
            format.html { redirect_to location_after_save }
            format.turbo_stream
          end
        else
          respond_with_error(@object.errors)
        end
      end

      def destroy
        @url_filters = ::ProductFilters.new.extract(request.query_parameters)
        destroy_before

        if @object.destroy
          flash[:success] = Spree.t(:successfully_removed)
        end

        redirect_to location_after_save
      end

      private

      def authorize_parent
        authorize! :update, parent
      end

      # The inherited handler redirects to the images list, which no longer exists.
      def resource_not_found
        flash[:error] = Spree.t(:not_found)
        redirect_to owner_edit_path
      end

      def find_resource
        parent.images.find(params[:id])
      end

      def build_resource
        Spree::Image.new(viewable: parent)
      end

      def parent
        return @parent if @parent

        if params[:variant_id]
          @parent = Spree::Variant.includes(:product).find(params[:variant_id])
          @variant = @parent
          @product = @variant.product
        else
          @parent = Spree::Product.find(params[:product_id])
          @product = @parent
        end

        @parent
      end

      def location_after_save
        return params[:return_url] if params[:return_url].present?
        return edit_image_path_after_upload if params[:edit_after_upload].present?

        owner_edit_path
      end

      # The image belongs to a product or a variant; that owner's edit page is where
      # every image action returns to now that the images list page is gone.
      def owner_edit_path
        return admin_products_url if @product.blank?

        helpers.image_owner_edit_path(@product, @variant)
      end

      def edit_image_path_after_upload
        extra = params[:variant_id].present? ? { variant_id: @variant.id } : {}
        edit_admin_product_image_path(@product.id, @object.id, extra)
      end

      # The id arrives in the request body, so fall back to the parent that has already
      # been resolved and authorized rather than trusting a blank value and saving an
      # image that points at no record (Spree::Asset doesn't require its parent).
      def set_viewable
        @image.viewable_type = params[:variant_id] ? 'Spree::Variant' : 'Spree::Product'
        @image.viewable_id = params[:image][:viewable_id].presence || parent.id
      end

      # An upload carries no caption field, so store the default up front rather than
      # relying on a display-time fallback. A caption cleared later is stored as "".
      def set_default_caption
        parent
        @object.caption = helpers.default_image_caption(@product, @variant)
      end

      def destroy_before
        @viewable = @image.viewable
      end

      def permitted_resource_params
        params.require(:image).permit(
          :attachment, :viewable_id, :alt, :caption
        )
      end

      def respond_with_error(errors)
        # The inline upload widget has no modal to re-render, so it only gets a flash.
        return respond_with_upload_error(errors) if params[:edit_after_upload].present?

        @errors = errors.map(&:full_message)
        respond_to do |format|
          # There is no HTML form for creating an image any more: the uploader on the
          # product/variant edit page posts it, so errors go back there as a flash.
          format.html {
            if action_name == 'create'
              flash[:error] = @errors.to_sentence
              redirect_to location_after_save
            else
              render :edit, status: :unprocessable_entity
            end
          }
          format.turbo_stream { render :edit, status: :unprocessable_entity }
        end
      end

      def respond_with_upload_error(errors)
        flash[:error] = errors.full_messages.to_sentence
        render :create_error, status: :unprocessable_entity
      end
    end
  end
end
