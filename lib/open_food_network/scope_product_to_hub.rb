require 'open_food_network/scope_variant_to_hub'

module OpenFoodNetwork
  module ScopeProductToHub
    def variants_distributed_by(order_cycle, distributor)
      super.each { |v| v.scope_to_hub @hub }
    end
  end
end

Spree::Product.class_eval do
  def scope_to_hub(hub)
    extend OpenFoodNetwork::ScopeProductToHub
    @hub = hub
  end
end
