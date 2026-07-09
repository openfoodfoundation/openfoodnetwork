# frozen_string_literal: true

module Spree
  module Admin
    class ImagesController < ::Admin::ResourceController
      helper ::Admin::ProductsHelper

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

        respond_with do |format|
          format.turbo_stream { render :edit }
          format.all { render layout: !request.xhr? }
        end
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

          respond_to do |format|
            format.html { redirect_to location_after_save }
            format.turbo_stream { render :update }
          end
        else
          respond_with_error((@error_target || @object).errors)
        end
      end

      def update
        @url_filters = ::ProductFilters.new.extract(request.query_parameters)
        update_successful = if permitted_resource_params[:attachment].present?
                              replace_image_without_destroy
                            else
                              set_viewable
                              @object.update(permitted_resource_params)
                            end

        if update_successful
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

      def collection
        parent.image
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

        if params[:variant_id]
          admin_products_url
        else
          spree.admin_product_images_url(params[:product_id], @url_filters)
        end
      end

      def load_data
        if params[:variant_id]
          @variant = Spree::Variant.find(params[:variant_id])
          @product = @variant.product
        else
          @product = Product.find(params[:product_id])
        end
      end

      def set_viewable
        @image.viewable_type = params[:variant_id] ? 'Spree::Variant' : 'Spree::Product'
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

      def respond_with_error(errors)
        @errors = errors.map(&:full_message)
        respond_to do |format|
          format.html {
            render action_name == 'create' ? :new : :edit, status: :unprocessable_entity
          }
          format.turbo_stream { render :edit, status: :unprocessable_entity }
        end
      end

      def replace_image_without_destroy
        previous_image = @object
        replacement_image = Spree::Image.new(viewable: previous_image.viewable)

        replacement_image.alt = previous_image.alt
        replacement_image.position = previous_image.position
        replacement_image.attributes = permitted_resource_params.except(:attachment, :viewable_id)
        replacement_image.viewable_type = previous_image.viewable_type
        replacement_image.viewable_id = params[:image][:viewable_id]
        replacement_image.attachment.attach(permitted_resource_params[:attachment])

        Spree::Image.transaction do
          replacement_image.save!
          previous_image.destroy!
        end

        @object = @image = replacement_image
      rescue ActiveRecord::RecordInvalid
        @error_target = replacement_image
        false
      end
    end
  end
end
