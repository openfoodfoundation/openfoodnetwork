class OrderCycleSet < ModelSet
  def initialize(attributes={})
    super(OrderCycle, OrderCycle.all, nil, attributes)
  end
end
