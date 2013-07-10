module Spree
  module Api
    class EnterprisesController < Spree::Api::BaseController
      respond_to :json

      def show
        @enterprise = Enterprise.find(params[:id])
        respond_with(@enterprise)
      end
    end
  end
end