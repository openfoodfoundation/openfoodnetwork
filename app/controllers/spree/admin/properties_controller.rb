module Spree
  module Admin
    class PropertiesController < ResourceController
      def permitted_resource_params
        params.require(:property).permit(:name, :presentation)
      end
    end
  end
end
