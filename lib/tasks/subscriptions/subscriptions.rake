# frozen_string_literal: true

namespace :ofn do
  namespace :subs do
    desc "Repeat placement job for a specific Order Cycle"
    task repeat_placement_job: :environment do
      puts "WARNING: this task will generate new, and potentially duplicate, orders for customers"

      puts "Please input Order Cycle ID to reset"
      input = STDIN.gets.chomp
      exit if input.blank? || !Integer(input)
      order_cycle_id = Integer(input)

      # Open Order Cycle by moving open_at to the past
      OrderCycle.find_by(id: order_cycle_id).update(orders_open_at: Time.zone.now - 1000)

      # Reset Proxy Orders of the Order Cycle
      #   by detatching them from existing orders and resetting placed and confirmed dates
      ProxyOrder.find_by(order_cycle_id: order_cycle_id).update(order_id: nil,
                                                                confirmed_at: nil,
                                                                placed_at: nil)

      # Run placement job to create orders
      SubscriptionPlacementJob.new.perform
    end
  end
end
