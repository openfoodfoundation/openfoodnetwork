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
      broker = FdcOfferBroker.new(spree_current_user, catalog_url)

      # * First step: import all products for given enterprise.
      # * Second step: render table and let user decide which ones to import.
      imported = broker.catalog.map do |subject|
        next unless subject.is_a? DataFoodConsortium::Connector::SuppliedProduct

        adjust_to_wholesale_price(broker, subject)

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
           ActionController::ParameterMissing => e
      flash[:error] = e.message
      redirect_to admin_product_import_path
    end

    private

    def adjust_to_wholesale_price(broker, product)
      transformation = broker.best_offer(product.semanticId)

      return if transformation.factor == 1

      wholesale_variant_price = transformation.offer.price

      return unless wholesale_variant_price

      offer = product.catalogItems&.first&.offers&.first

      return unless offer

      offer.price = wholesale_variant_price.dup
      offer.price.value = offer.price.value.to_f / transformation.factor
    end
  end
end
