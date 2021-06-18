# frozen_string_literal: true

require 'open_food_network/scope_variant_to_hub'

module OpenFoodNetwork
  class ScopeProductToHub
    def initialize(hub)
      @hub = hub
      @variant_overrides = VariantOverride.indexed(@hub)
    end

    def scope(product)
      product.extend(OpenFoodNetwork::ScopeProductToHub::ScopeProductToHub)
      product.instance_variable_set :@hub, @hub
      product.instance_variable_set :@variant_overrides, @variant_overrides
    end

    module ScopeProductToHub
      def variants_distributed_by(order_cycle, distributor)
        super.each { |v| ScopeVariantToHub.new(@hub, @variant_overrides).scope(v) }
      end
    end
  end
end
