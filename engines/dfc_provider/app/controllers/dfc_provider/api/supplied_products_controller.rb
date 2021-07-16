# frozen_string_literal: true

# Controller used to provide the SuppliedProducts API for the DFC application
# SuppliedProducts are products that are managed by an enterprise.
module DfcProvider
  module Api
    class SuppliedProductsController < DfcProvider::Api::BaseController
      before_action :check_enterprise

      def show
        render json: variant, serializer: DfcProvider::SuppliedProductSerializer
      end

      private

      def variant
        @variant ||=
          DfcProvider::VariantFetcher.new(current_enterprise).scope.find(params[:id])
      end
    end
  end
end
