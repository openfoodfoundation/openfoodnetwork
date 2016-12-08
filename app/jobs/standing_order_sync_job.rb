class StandingOrderSyncJob
  attr_accessor :schedule

  def initialize(schedule)
    @schedule = schedule
  end

  def perform
    standing_orders.each do |standing_order|
      form = StandingOrderForm.new(standing_order)
      form.send(:initialise_orders!)
      form.send(:remove_obsolete_orders!)
    end
  end

  private

  def standing_orders
    StandingOrder.not_ended.not_canceled.where(schedule_id: schedule)
  end
end
