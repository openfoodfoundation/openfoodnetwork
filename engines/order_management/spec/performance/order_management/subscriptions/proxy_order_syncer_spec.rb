# frozen_string_literal: true

module OrderManagement
  module Subscriptions
    describe ProxyOrderSyncer, performance: true do
      let(:start) { Time.zone.now.beginning_of_day }
      let!(:schedule) { create(:schedule, order_cycles: order_cycles) }

      let!(:order_cycles) do
        Array.new(10) do |i|
          create(:simple_order_cycle, orders_open_at: start + i.days,
                                      orders_close_at: start + (i + 1).days )
        end
      end

      let!(:subscriptions) do
        Array.new(150) do |_i|
          create(:subscription, schedule: schedule, begins_at: start, ends_at: start + 10.days)
        end
        Subscription.where(schedule_id: schedule)
      end

      context "measuring performance for initialisation" do
        it "reports the average run time for adding 10 OCs to 150 subscriptions" do
          expect(ProxyOrder.count).to be 0
          times = []
          10.times do
            syncer = ProxyOrderSyncer.new(subscriptions.reload)

            t1 = Time.zone.now
            syncer.sync!
            t2 = Time.zone.now
            diff = t2 - t1
            times << diff
            puts diff.round(2)

            expect(ProxyOrder.count).to be 1500
            ProxyOrder.destroy_all
          end
          puts "AVG: #{(times.sum / times.count).round(2)}"
        end
      end

      context "measuring performance for removal" do
        it "reports the average run time for removing 8 OCs from 150 subscriptions" do
          times = []
          10.times do
            syncer = ProxyOrderSyncer.new(subscriptions.reload)
            syncer.sync!
            expect(ProxyOrder.count).to be 1500
            subscriptions.update_all(begins_at: start + 8.days + 1.minute)
            syncer = ProxyOrderSyncer.new(subscriptions.reload)

            t1 = Time.zone.now
            syncer.sync!
            t2 = Time.zone.now
            diff = t2 - t1
            times << diff
            puts diff.round(2)

            expect(ProxyOrder.count).to be 300
            subscriptions.update_all(begins_at: start)
          end
          puts "AVG: #{(times.sum / times.count).round(2)}"
        end
      end
    end
  end
end
