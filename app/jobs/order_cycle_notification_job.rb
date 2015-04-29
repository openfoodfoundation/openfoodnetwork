OrderCycleNotificationJob = Struct.new(:order_cycle_id) do
  def perform
    order_cycle = OrderCycle.find order_cycle_id
    order_cycle.suppliers.each { |supplier| ProducerMailer.order_cycle_report(supplier, order_cycle).deliver }
  end
end
