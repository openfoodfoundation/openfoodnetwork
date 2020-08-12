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
            @user.enterprises.first
          else
            @user.enterprises.where(id: params[:id]).first
          end

        return if @enterprise.present?

        head :not_found
      end
    end
  end
end
