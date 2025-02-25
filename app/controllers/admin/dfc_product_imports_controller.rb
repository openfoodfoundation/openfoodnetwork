# frozen_string_literal: true

require "private_address_check"
require "private_address_check/tcpsocket_ext"

module Admin
  class DfcProductImportsController < Spree::Admin::BaseController
    before_action :load_enterprise

    # Define model class for `can?` permissions:
    def model_class
      self.class
    end

    def index
      # Fetch DFC catalog JSON for preview
      api = DfcRequest.new(spree_current_user)
      @catalog_url = params.require(:catalog_url)
      @catalog_json = api.call(@catalog_url)
      graph = DfcIo.import(@catalog_json)
      catalog = DfcCatalog.new(graph)

      # Render table and let user decide which ones to import.
      @items = catalog.products.map do |subject|
        [
          subject,
          @enterprise.supplied_variants.linked_to(subject.semanticId)&.product
        ]
      end
    rescue URI::InvalidURIError
      flash[:error] = t ".invalid_url"
      redirect_to admin_product_import_path
    rescue Faraday::Error,
           Addressable::URI::InvalidURIError,
           ActionController::ParameterMissing => e
      flash[:error] = e.message
      redirect_to admin_product_import_path
    rescue Rack::OAuth2::Client::Error
      oidc_settings_link = helpers.link_to(
        t('spree.admin.tab.oidc_settings'),
        admin_oidc_settings_path
      )
      flash[:error] = t(".connection_invalid_html", oidc_settings_link:)
      redirect_to admin_product_import_path
    end

    def import
      ids = params.require(:semanticIds)

      # Load DFC catalog JSON
      graph = DfcIo.import(params.require(:catalog_json))
      catalog = DfcCatalog.new(graph)
      catalog.apply_wholesale_values!

      # Import all selected products for given enterprise.
      imported = ids.map do |semantic_id|
        subject = catalog.item(semantic_id)
        existing_variant = @enterprise.supplied_variants.linked_to(semantic_id)

        if existing_variant
          SuppliedProductImporter.update_product(subject, existing_variant)
        else
          SuppliedProductImporter.store_product(subject, @enterprise)
        end
      end

      @count = imported.compact.count
    rescue ActionController::ParameterMissing => e
      flash[:error] = e.message
      redirect_to admin_product_import_path
    end

    private

    def load_enterprise
      @enterprise = OpenFoodNetwork::Permissions.new(spree_current_user)
        .managed_product_enterprises.is_primary_producer
        .find(params.require(:enterprise_id))
    end
  end
end
