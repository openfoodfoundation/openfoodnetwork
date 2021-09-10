# frozen_string_literal: true

# Lists available order cycles for a given customer in a given distributor
module Shop
  class OrderCyclesList
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

    # order_cycles is a ActiveRecord::Relation that is modified with reject in the TagRuleApplicator
    # If this relation is reloaded (for example by calling count on it), the modifications are lost
    def apply_tag_rules!(order_cycles)
      applicator = OpenFoodNetwork::TagRuleApplicator.new(@distributor,
                                                          "FilterOrderCycles",
                                                          @customer&.tag_list)
      applicator.filter!(order_cycles)

      order_cycles
    end
  end
end
