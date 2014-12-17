module OpenFoodNetwork
  module ScopeVariantToHub
    def price
      VariantOverride.price_for(@hub, self) || super
    end

    def count_on_hand
      VariantOverride.count_on_hand_for(@hub, self) || super
    end
  end
end

Spree::Variant.class_eval do
  def scope_to_hub(hub)
    extend OpenFoodNetwork::ScopeVariantToHub
    @hub = hub
  end
end
