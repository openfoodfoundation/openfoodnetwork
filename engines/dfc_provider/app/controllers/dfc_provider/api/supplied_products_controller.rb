# frozen_string_literal: true

# Controller used to provide the SuppliedProducts API for the DFC application
# SuppliedProducts are products that are managed by an entrerprise.
module DfcProvider
  module Api
    class SuppliedProductsController < DfcProvider::Api::BaseController
      def show
        render json: variant, serializer: DfcProvider::SuppliedProductSerializer
      end

      private

      def variant
        @variant ||=
          Spree::Variant.
            joins(product: :supplier).
            where('enterprises.id' => current_enterprise.id).
            find(params[:id])
      end
    end
  end
end
