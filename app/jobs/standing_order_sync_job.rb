require 'open_food_network/proxy_order_syncer'

class StandingOrderSyncJob
  attr_accessor :schedule

  def initialize(schedule)
    @schedule = schedule
  end

  def perform
    proxy_order_syncer.sync!
  end

  private

  def standing_orders
    StandingOrder.not_ended.not_canceled.where(schedule_id: schedule)
  end

  def proxy_order_syncer
    OpenFoodNetwork::ProxyOrderSyncer.new(standing_orders)
  end
end
