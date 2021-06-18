# frozen_string_literal: true

module Spree
  module Admin
    class ShippingCategoriesController < ::Admin::ResourceController
      protected

      def permitted_resource_params
        params.require(:shipping_category).
          permit(:name, :temperature_controlled)
      end
    end
  end
end
