module Spree
  module Api
    class EnterprisesController < Spree::Api::BaseController
      respond_to :json

      def bulk_show
        @enterprise = Enterprise.find(params[:id])
        respond_with(@enterprise)
      end

      def bulk_index
        @enterprises = Enterprise.ransack(params[:q]).result
        respond_with(@enterprises)
      end
    end
  end
end