# frozen_string_literal: true

# Controller used to provide the CatalogItem API for the DFC application
module DfcProvider
  module Api
    class EnterprisesController < BaseController
      def show
        render json: current_enterprise, serializer: DfcProvider::EnterpriseSerializer
      end

      private

      def current_enterprise
        @current_enterprise ||=
          if params[:id] == 'default'
            current_user.enterprises.first!
          else
            current_user.enterprises.find(params[:id])
          end
      end
    end
  end
end
