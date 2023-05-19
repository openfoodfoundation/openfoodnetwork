# frozen_string_literal: true

# Controller used to provide the API products for the DFC application
# CatalogItems are items that are being sold by the entreprise.
module DfcProvider
  class CatalogItemsController < DfcProvider::BaseController
    before_action :check_enterprise

    def index
      person = PersonBuilder.person(current_user)
      render json: DfcLoader.connector.export(
        person,
        *person.affiliatedOrganizations,
        *person.affiliatedOrganizations.flat_map(&:catalogItems),
        *person.affiliatedOrganizations.flat_map(&:catalogItems).map(&:product),
        *person.affiliatedOrganizations.flat_map(&:catalogItems).flat_map(&:offers),
      )
    end

    def show
      catalog_item = DfcBuilder.catalog_item(variant)
      offers = catalog_item.offers
      render json: DfcLoader.connector.export(catalog_item, *offers)
    end

    private

    def variant
      @variant ||=
        VariantFetcher.new(current_enterprise).scope.find(params[:id])
    end
  end
end
