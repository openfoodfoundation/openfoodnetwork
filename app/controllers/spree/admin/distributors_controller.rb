module Spree
  module Admin
    class DistributorsController < ResourceController
      before_filter :load_distributor_set, :only => :index
      before_filter :load_countries, :except => :index

      def bulk_update
        @distributor_set = DistributorSet.new(params[:distributor_set])
        if @distributor_set.save
          redirect_to admin_distributors_path, :notice => 'Distributor collection times updated.'
        else
          render :index
        end
      end

      private
      def load_distributor_set
        @distributor_set = Spree::DistributorSet.new :distributors => collection
      end

      def load_countries
        @countries = Country.order(:name)
      end

      def collection
        super.order(:name)
      end
    end
  end
end
