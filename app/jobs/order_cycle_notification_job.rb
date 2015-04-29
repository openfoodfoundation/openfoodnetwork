
OrderCycleNotificationJob = Struct.new(:order_cycle) do
  def perform
    order_cycle.suppliers.each { |supplier| ProducerMailer.order_cycle_report(supplier, order_cycle).deliver }
  end
end

