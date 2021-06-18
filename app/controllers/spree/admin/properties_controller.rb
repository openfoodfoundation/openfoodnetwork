# frozen_string_literal: true

module Spree
  module Admin
    class PropertiesController < ::Admin::ResourceController
      def permitted_resource_params
        params.require(:property).permit(:name, :presentation)
      end
    end
  end
end
