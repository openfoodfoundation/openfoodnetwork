class OrderCycleSet < ModelSet
  def initialize(attributes={})
    super(OrderCycle, OrderCycle.all, attributes)
  end
end
