# frozen_string_literal: true

# Controller used to provide the API products for the DFC application
# CatalogItems are items that are being sold by the entreprise.
module DfcProvider
  class CatalogItemsController < DfcProvider::BaseController
    before_action :check_enterprise

    def index
      # CatalogItem is nested into an entreprise which is also nested into
      # an user on the DFC specifications, as defined here:
      # https://datafoodconsortium.gitbook.io/dfc-standard-documentation
      #  /technical-specification/api-examples
      render json: current_user, serializer: DfcProvider::PersonSerializer
    end

    def show
      dfc_object = DfcBuilder.catalog_item(variant)
      render json: DfcLoader.connector.export(dfc_object)
    end

    private

    def variant
      @variant ||=
        VariantFetcher.new(current_enterprise).scope.find(params[:id])
    end
  end
end
