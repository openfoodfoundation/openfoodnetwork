class OrderCycleOpenCloseJob
  def perform
    Delayed::Job.enqueue(StandingOrderPlacementJob.new)
    Delayed::Job.enqueue(StandingOrderConfirmJob.new)
  end
end
