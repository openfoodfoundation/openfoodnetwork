# frozen_string_literal: true

# Controller used to provide the API products for the DFC application
# CatalogItems are items that are being sold by the entreprise.
module DfcProvider
  class CatalogItemsController < DfcProvider::BaseController
    before_action :check_enterprise

    def index
      person = PersonBuilder.person(current_user)
      render json: DfcIo.export(
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
      render json: DfcIo.export(catalog_item, *offers)
    end

    def update
      dfc_request = JSON.parse(request.body.read)

      variant.on_hand = dfc_request["dfc-b:stockLimitation"]
      variant.sku = dfc_request["dfc-b:sku"]
      variant.save!
    end

    private

    def variant
      @variant ||=
        VariantFetcher.new(current_enterprise).scope.find(params[:id])
    end
  end
end
