
OrderCycleNotificationJob = Struct.new(:order_cycle) do
  def perform
    @suppliers = order_cycle.suppliers
    @suppliers.each { |supplier| ProducerMailer.order_cycle_report(supplier, order_cycle).deliver }
  end
end

