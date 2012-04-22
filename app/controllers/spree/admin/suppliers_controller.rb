module Spree
  module Admin
    class SuppliersController < ResourceController
      # before_filter :load_data, :except => [:index]

      private
      def collection
          super.order(:name)
      end
    end
  end
end