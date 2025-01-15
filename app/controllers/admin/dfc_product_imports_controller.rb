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
      catalog = DfcCatalog.load(spree_current_user, catalog_url)
      catalog.apply_wholesale_values!

      # * First step: import all products for given enterprise.
      # * Second step: render table and let user decide which ones to import.
      imported = catalog.products.map do |subject|
        existing_variant = enterprise.supplied_variants.linked_to(subject.semanticId)

        if existing_variant
          SuppliedProductBuilder.update_product(subject, existing_variant)
        else
          SuppliedProductBuilder.store_product(subject, enterprise)
        end
      end

      @count = imported.compact.count
    rescue Faraday::Error,
           Addressable::URI::InvalidURIError,
           ActionController::ParameterMissing,
           Rack::OAuth2::Client::Error => e
      flash[:error] = e.message
      redirect_to admin_product_import_path
    end
  end
end
