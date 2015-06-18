require 'open_food_network/scope_variant_to_hub'

module OpenFoodNetwork
  class ScopeProductToHub
    def initialize(hub)
      @hub = hub
    end

    def scope(product)
      product.send :extend, OpenFoodNetwork::ScopeProductToHub::ScopeProductToHub
      product.instance_variable_set :@hub, @hub
    end


    module ScopeProductToHub
      def variants_distributed_by(order_cycle, distributor)
        super.each { |v| ScopeVariantToHub.new(@hub).scope(v) }
      end
    end
  end
end
