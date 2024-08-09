# frozen_string_literal: true

module OpenFoodNetwork
  class EnterpriseInjectionData
    # By default, data is fetched for *every* enterprise in the DB, but we specify some ids of
    # enterprises that we are interested in, there is a lot less data to fetch
    def initialize(enterprise_ids = nil)
      @enterprise_ids = enterprise_ids
    end

    def active_distributor_ids
      @active_distributor_ids ||=
        begin
          enterprises = Enterprise.distributors_with_active_order_cycles.ready_for_checkout
          enterprises = enterprises.where(id: @enterprise_ids) if @enterprise_ids.present?
          enterprises.pluck(:id)
        end
    end

    def earliest_closing_times
      @earliest_closing_times ||= OrderCycle.earliest_closing_times(@enterprise_ids)
    end

    def shipping_method_services
      @shipping_method_services ||= CacheService.cached_data_by_class(
        "shipping_method_services_#{@enterprise_ids.hash}",
        Spree::ShippingMethod
      ) do
        # This result relies on a simple join with DistributorShippingMethod.
        # Updated DistributorShippingMethod records touch their associated Spree::ShippingMethod.
        Spree::ShippingMethod.services(@enterprise_ids)
      end
    end

    def supplied_taxons
      @supplied_taxons ||= CacheService.cached_data_by_class(
        "supplied_taxons_#{@enterprise_ids.hash}",
        Spree::Taxon
      ) do
        # This result relies on a join with associated supplied products, through the
        # class Classification which maps the relationship. Classification records touch
        # their associated Spree::Taxon when updated. A Spree::Product's primary_taxon
        # is also touched when changed.
        Spree::Taxon.supplied_taxons(@enterprise_ids)
      end
    end

    def all_distributed_taxons
      @all_distributed_taxons ||= Spree::Taxon.distributed_taxons(:all, @enterprise_ids)
    end

    def current_distributed_taxons
      @current_distributed_taxons ||= Spree::Taxon.distributed_taxons(:current, @enterprise_ids)
    end
  end
end
