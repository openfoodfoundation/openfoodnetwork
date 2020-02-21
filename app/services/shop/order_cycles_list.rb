# frozen_string_literal: true

# Lists available order cycles for a given customer in a given distributor

class OrderCyclesList
  def initialize(distributor, customer)
    @distributor = distributor
    @customer = customer
  end

  def call
    order_cycles = OrderCycle.with_distributor(@distributor).active
      .order(@distributor.preferred_shopfront_order_cycle_order)

    applicator = OpenFoodNetwork::TagRuleApplicator.new(@distributor,
                                                        "FilterOrderCycles",
                                                        @customer.andand.tag_list)
    applicator.filter!(order_cycles)

    order_cycles
  end
end
