module OpenFoodNetwork
  class EnterpriseInjectionData
    def active_distributors
      @active_distributors ||= Enterprise.distributors_with_active_order_cycles.ready_for_checkout
    end

    def earliest_closing_times
      @earliest_closing_times ||= OrderCycle.earliest_closing_times
    end

    def shipping_method_services
      @shipping_method_services ||= Spree::ShippingMethod.services
    end

    def relatives
      @relatives ||= EnterpriseRelationship.relatives(true)
    end

    def supplied_taxons
      @supplied_taxons ||= Spree::Taxon.supplied_taxons
    end

    def all_distributed_taxons
      @all_distributed_taxons ||= Spree::Taxon.distributed_taxons(:all)
    end

    def current_distributed_taxons
      @current_distributed_taxons ||= Spree::Taxon.distributed_taxons(:current)
    end
  end
end
