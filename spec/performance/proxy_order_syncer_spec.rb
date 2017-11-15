require 'open_food_network/proxy_order_syncer'

module OpenFoodNetwork
  describe ProxyOrderSyncer, performance: true do
    let(:start) { Time.zone.now.beginning_of_day }
    let!(:schedule) { create(:schedule, order_cycles: order_cycles) }

    let!(:order_cycles) do
      10.times.map do |i|
        create(:simple_order_cycle, orders_open_at: start + i.days, orders_close_at: start + (i+1).days )
      end
    end

    let!(:standing_orders) do
      150.times.map do |i|
        create(:standing_order, schedule: schedule, begins_at: start, ends_at: start + 10.days)
      end
      StandingOrder.where(schedule_id: schedule)
    end

    context "measuring performance for initialisation" do
      it "reports the average run time for adding 10 OCs to 150 standing orders" do
        expect(ProxyOrder.count).to be 0
        times = []
        10.times do
          syncer = ProxyOrderSyncer.new(standing_orders.reload)

          t1 = Time.now
          syncer.sync!
          t2 = Time.now
          times << t2-t1
          puts (t2-t1).round(2)

          expect(ProxyOrder.count).to be 1500
          ProxyOrder.destroy_all
        end
        puts "AVG: #{(times.sum/times.count).round(2)}"
      end
    end

    context "measuring performance for removal" do
      it "reports the average run time for removing 8 OCs from 150 standing orders" do
        times = []
        10.times do
          syncer = ProxyOrderSyncer.new(standing_orders.reload)
          syncer.sync!
          expect(ProxyOrder.count).to be 1500
          standing_orders.update_all(begins_at: start + 8.days + 1.minute)
          syncer = ProxyOrderSyncer.new(standing_orders.reload)

          t1 = Time.now
          syncer.sync!
          t2 = Time.now
          times << t2-t1
          puts (t2-t1).round(2)

          expect(ProxyOrder.count).to be 300
          standing_orders.update_all(begins_at: start)
        end
        puts "AVG: #{(times.sum/times.count).round(2)}"
      end
    end
  end
end
