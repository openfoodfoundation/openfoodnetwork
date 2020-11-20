# frozen_string_literal: true

namespace :ofn do
  namespace :subs do
    namespace :test do
      desc "Repeat placement job for a specific Order Cycle"
      task repeat_placement_job: :environment do
        puts "WARNING: this task will generate new, and potentially duplicate, customer orders"

        order_cycle_id = request_order_cycle_id

        # Open Order Cycle by moving close_at to the future and open_at to the past
        set_order_cycle_times(order_cycle_id,
                              Time.zone.now - 15.minutes,
                              Time.zone.now + 15.minutes)

        # Reset Proxy Orders of the Order Cycle
        #   by detatching them from existing orders and resetting placed and confirmed dates
        ProxyOrder.find_by(order_cycle_id: order_cycle_id)&.update(order_id: nil,
                                                                  confirmed_at: nil,
                                                                  placed_at: nil)

        # Run placement job to create orders
        SubscriptionPlacementJob.new.perform
      end

      desc "Force confirmation job for a specific Order Cycle"
      task force_confirmation_job: :environment do
        puts "WARNING: this task will process payments in customer orders"

        order_cycle_id = request_order_cycle_id

        # Close Orde Cycle by moving close_at to the past
        set_order_cycle_times(order_cycle_id,
                              Time.zone.now - 30.minutes,
                              Time.zone.now - 15.minutes)

        # Run Confirm Job to process payments
        SubscriptionConfirmJob.new.perform
      end

      def set_order_cycle_times(order_cycle_id, open_at, close_at)
        OrderCycle.find_by(id: order_cycle_id).update(orders_open_at: open_at,
                                                      orders_close_at: close_at)
      end

      def request_order_cycle_id
        puts "Please input Order Cycle ID to reset"
        input = STDIN.gets.chomp
        exit if input.blank? || !Integer(input)
        Integer(input)
      end
    end
  end
end
