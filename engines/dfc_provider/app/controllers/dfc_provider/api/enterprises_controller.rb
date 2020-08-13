# frozen_string_literal: true

# Controller used to provide the CatalogItem API for the DFC application
module DfcProvider
  module Api
    class EnterprisesController < BaseController
      def show
        render json: @enterprise, serializer: DfcProvider::EnterpriseSerializer
      end

      private

      def check_enterprise
        @enterprise =
          if params[:id] == 'default'
            @user.enterprises.first!
          else
            @user.enterprises.find(params[:id])
          end
      end
    end
  end
end
