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
      @shipping_method_services ||= begin
        CacheService.cached_data_by_class("shipping_method_services", Spree::ShippingMethod) do
          Spree::ShippingMethod.services
        end
      end
    end

    def supplied_taxons
      @supplied_taxons ||= begin
        CacheService.cached_data_by_class("supplied_taxons", Spree::Taxon) do
          Spree::Taxon.supplied_taxons
        end
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
