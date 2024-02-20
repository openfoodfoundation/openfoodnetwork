# frozen_string_literal: true

require "private_address_check"
require "private_address_check/tcpsocket_ext"

module Admin
  class DfcProductImportsController < Spree::Admin::BaseController
    # Define model class for `can?` permissions:
    def model_class
      self.class
    end

    def index
      # The plan:
      #
      # * Fetch DFC catalog as JSON from URL.
      enterprise = OpenFoodNetwork::Permissions.new(spree_current_user)
        .managed_product_enterprises.is_primary_producer
        .find(params.require(:enterprise_id))

      catalog_url = params.require(:catalog_url)

      json_catalog = fetch_catalog(catalog_url)
      graph = DfcIo.import(json_catalog)

      # * First step: import all products for given enterprise.
      # * Second step: render table and let user decide which ones to import.
      imported = graph.map do |subject|
        import_product(subject, enterprise)
      end

      @count = imported.compact.count
    end

    private

    def fetch_catalog(url)
      connection = Faraday.new(
        request: { timeout: 30 },
        headers: {
          'Content-Type' => 'application/json',
          'Authorization' => "Bearer #{spree_current_user.oidc_account.token}",
        }
      )
      response = PrivateAddressCheck.only_public_connections do
        connection.get(url)
      end

      response.body
    end

    # Most of this code is the same as in the DfcProvider::SuppliedProductsController.
    def import_product(subject, enterprise)
      return unless subject.is_a? DataFoodConsortium::Connector::SuppliedProduct

      variant = SuppliedProductBuilder.import_variant(subject, enterprise)
      product = variant.product

      product.save! if product.new_record?
      variant.save! if variant.new_record?

      variant
    end
  end
end
