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
      @catalog_url = params.require(:catalog_url).strip
      @catalog_json = api.call(@catalog_url)
      catalog = DfcCatalog.from_json(@catalog_json)

      # Render table and let user decide which ones to import.
      @items = list_products(catalog)
      @absent_items = absent_variants(catalog)
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
      catalog = DfcCatalog.from_json(params.require(:catalog_json))
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
      @reset_count = reset_absent_variants(catalog).count
    rescue ActionController::ParameterMissing => e
      flash[:error] = e.message
      redirect_to admin_product_import_path
    end

    private

    def api
      @api ||= DfcRequest.new(spree_current_user)
    end

    def load_enterprise
      @enterprise = OpenFoodNetwork::Permissions.new(spree_current_user)
        .managed_product_enterprises.is_primary_producer
        .find(params.require(:enterprise_id))
    end

    # List internal and external products for the preview.
    def list_products(catalog)
      catalog.products.map do |subject|
        [
          subject,
          @enterprise.supplied_variants.linked_to(subject.semanticId)&.product
        ]
      end
    end

    # Reset stock for any variants that were removed from the catalog.
    #
    # When variants are removed from the remote catalog, we can't place
    # backorders for them anymore. If our copy of the product has limited
    # stock then we need to set the stock to zero to prevent any more sales.
    #
    # But if our product is on-demand/backorderable then our stock level is
    # a representation of remaining local stock. We then need to limit sales
    # to this local stock and set on-demand to false.
    #
    # We don't delete the variant because it may come back at a later time and
    # we don't want to lose the connection to previous orders.
    def reset_absent_variants(catalog)
      absent_variants(catalog).map do |variant|
        if variant.on_demand
          variant.on_demand = false
        else
          variant.on_hand = 0
        end
      end
    end

    def absent_variants(catalog)
      present_ids = catalog.products.map(&:semanticId)
      catalog_url = FdcUrlBuilder.new(present_ids.first).catalog_url

      @enterprise.supplied_variants
        .includes(:semantic_links).references(:semantic_links)
        .where.not(semantic_links: { semantic_id: present_ids })
        .select do |variant|
        # Variants that were in the same catalog before:
        variant.semantic_links.map(&:semantic_id).any? do |semantic_id|
          FdcUrlBuilder.new(semantic_id).catalog_url == catalog_url
        end
      end
    end
  end
end
