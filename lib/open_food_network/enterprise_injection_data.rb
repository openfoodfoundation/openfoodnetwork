# frozen_string_literal: true

module OpenFoodNetwork
  class EnterpriseInjectionData
    def active_distributor_ids
      @active_distributor_ids ||=
        Enterprise.distributors_with_active_order_cycles.ready_for_checkout.pluck(:id)
    end

    def earliest_closing_times
      @earliest_closing_times ||= OrderCycle.earliest_closing_times
    end

    def shipping_method_services
      @shipping_method_services ||= CacheService.cached_data_by_class("shipping_method_services",
                                                                      Spree::ShippingMethod) do
        # This result relies on a simple join with DistributorShippingMethod.
        # Updated DistributorShippingMethod records touch their associated Spree::ShippingMethod.
        Spree::ShippingMethod.services
      end
    end

    def supplied_taxons
      @supplied_taxons ||= CacheService.cached_data_by_class("supplied_taxons", Spree::Taxon) do
        # This result relies on a join with associated supplied products, through the
        # class Classification which maps the relationship. Classification records touch
        # their associated Spree::Taxon when updated. A Spree::Product's primary_taxon
        # is also touched when changed.
        Spree::Taxon.supplied_taxons
      end
    end

    def all_distributed_taxons
      @all_distributed_taxons ||= Spree::Taxon.distributed_taxons(:all)
    end

    def current_distributed_taxons
      @current_distributed_taxons ||= Spree::Taxon.distributed_taxons(:current)
    end
  end
end
