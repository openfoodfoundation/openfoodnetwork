# frozen_string_literal: true

module Spree
  module Admin
    class TaxCategoriesController < ::Admin::ResourceController
      def destroy
        if @object.destroy
          flash[:success] = flash_message_for(@object, :successfully_removed)
          respond_with(@object) do |format|
            format.html { redirect_to collection_url }
            format.js   { render partial: "spree/admin/shared/destroy" }
          end
        else
          respond_with(@object) do |format|
            format.html { redirect_to collection_url }
          end
        end
      end

      private

      def permitted_resource_params
        params.require(:tax_category).permit(:name, :description, :is_default)
      end
    end
  end
end
