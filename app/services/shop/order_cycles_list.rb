# frozen_string_literal: true

# Lists available order cycles for a given customer in a given distributor
module Shop
  class OrderCyclesList
    def self.active_for(distributor, customer)
      new(distributor, customer).call
    end

    def self.ready_for_checkout_for(distributor, customer)
      new(distributor, customer).call.select do |order_cycle|
        order = Spree::Order.new(distributor: distributor, order_cycle: order_cycle)
        OrderAvailablePaymentMethods.new(order, customer).to_a.any? &&
          OrderAvailableShippingMethods.new(order, customer).to_a.any?
      end
    end

    def initialize(distributor, customer)
      @distributor = distributor
      @customer = customer
    end

    def call
      order_cycles = OrderCycle.with_distributor(@distributor).active
        .order(@distributor.preferred_shopfront_order_cycle_order).to_a

      apply_tag_rules!(order_cycles)
    end

    private

    def apply_tag_rules!(order_cycles)
      applicator = OpenFoodNetwork::TagRuleApplicator.new(@distributor,
                                                          "FilterOrderCycles",
                                                          @customer&.tag_list)
      applicator.filter(order_cycles)
    end
  end
end
