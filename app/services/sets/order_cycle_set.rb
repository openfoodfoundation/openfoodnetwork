# frozen_string_literal: true

module Sets
  class OrderCycleSet < ModelSet
    def initialize(collection, attributes = {})
      super(OrderCycle, collection, attributes)
    end
  end
end
