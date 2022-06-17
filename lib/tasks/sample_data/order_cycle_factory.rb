# frozen_string_literal: true

require "tasks/sample_data/logging"

module SampleData
  class OrderCycleFactory
    include Logging
    # rubocop:disable Metrics/MethodLength
    def create_samples
      log "Creating order cycles"
      create_order_cycle(
        "Freddy's Farm Shop OC",
        "Freddy's Farm Shop",
        ["Freddy's Farm Shop"],
        ["Freddy's Farm Shop"],
        receival_instructions: "Dear self, don't forget the keys.",
        pickup_time: "the weekend",
        pickup_instructions: "Bring your own shopping bags or boxes."
      )

      create_order_cycle(
        "Fredo's Farm Hub OC",
        "Fredo's Farm Hub",
        ["Fred's Farm", "Fredo's Farm Hub"],
        ["Fredo's Farm Hub"],
        receival_instructions: "Under the shed, please.",
        pickup_time: "Wednesday 2pm",
        pickup_instructions: "Boxes for packaging under the roof."
      )

      create_order_cycle(
        "Mary's Online Shop OC",
        "Mary's Online Shop",
        ["Fred's Farm", "Freddy's Farm Shop", "Fredo's Farm Hub"],
        ["Mary's Online Shop"],
        receival_instructions: "Please shut the gate.",
        pickup_time: "midday"
      )

      create_order_cycle(
        "Multi Shop OC",
        "Mary's Online Shop",
        ["Fred's Farm", "Freddy's Farm Shop", "Fredo's Farm Hub"],
        ["Mary's Online Shop", "Maryse's Private Shop"],
        receival_instructions: "Please shut the gate.",
        pickup_time: "dusk"
      )
    end
    # rubocop:enable Metrics/MethodLength

    private

    def create_order_cycle(name, coordinator_name, supplier_names, distributor_names, data)
      coordinator = Enterprise.find_by(name: coordinator_name)
      return if OrderCycle.active.where(name: name).exists?

      log "- #{name}"
      cycle = create_order_cycle_with_fee(name, coordinator)
      create_exchanges(cycle, supplier_names, distributor_names, data)
    end

    def create_order_cycle_with_fee(name, coordinator)
      cycle = OrderCycle.create!(
        name: name,
        orders_open_at: 1.day.ago,
        orders_close_at: 1.month.from_now,
        coordinator: coordinator
      )
      cycle.coordinator_fees << coordinator.enterprise_fees.first
      cycle
    end

    def create_exchanges(cycle, supplier_names, distributor_names, data)
      suppliers = Enterprise.where(name: supplier_names)
      distributors = Enterprise.where(name: distributor_names)

      incoming = incoming_exchanges(cycle, suppliers, data)
      outgoing = outgoing_exchanges(cycle, distributors, data)
      all_exchanges = incoming + outgoing
      add_products(suppliers, all_exchanges)
    end

    def incoming_exchanges(cycle, suppliers, data)
      suppliers.map do |supplier|
        Exchange.create!(
          order_cycle: cycle,
          sender: supplier,
          receiver: cycle.coordinator,
          incoming: true,
          receival_instructions: data[:receival_instructions]
        )
      end
    end

    def outgoing_exchanges(cycle, distributors, data)
      distributors.map do |distributor|
        Exchange.create!(
          order_cycle: cycle,
          sender: cycle.coordinator,
          receiver: distributor,
          incoming: false,
          pickup_time: data[:pickup_time],
          pickup_instructions: data[:pickup_instructions]
        )
      end
    end

    def add_products(suppliers, exchanges)
      products = suppliers.flat_map(&:supplied_products)
      products.each do |product|
        exchanges.each { |exchange| exchange.variants << product.variants.first }
      end
    end
  end
end
