module Spree
  module Admin
    class DistributorsController < ResourceController
      before_filter :load_data, :except => [:index]

      private
      def load_data
          @countries = Country.order(:name)
      end
    end
  end
end