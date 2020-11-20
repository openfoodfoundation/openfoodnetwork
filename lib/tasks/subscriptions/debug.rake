# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
namespace :ofn do
  namespace :subs do
    namespace :debug do
      desc "Print standard info about a specific Order Cycle"
      task order_cycle: :environment do
        order_cycle_id = request_order_cycle_id

        order_cycle = OrderCycle.find_by(id: order_cycle_id)
        puts "Order Cycle #{order_cycle.name}"
        order_cycle.schedules.each do |schedule|
          puts "Schedule #{schedule.name}"
          Subscription.where(schedule_id: schedule.id).each do |subscription|
            puts
            puts "Subscription #{subscription.id}"
            puts subscription.shop.name
            puts subscription.customer.email
            puts subscription.payment_method.name
            puts "Active from #{subscription.begins_at} to #{subscription.ends_at}"
            puts "Last edited on #{subscription.updated_at}"
            puts "Canceled at #{subscription.canceled_at} and paused at #{subscription.paused_at}"

            ProxyOrder.where(order_cycle_id: order_cycle_id,
                             subscription_id: subscription.id).each do |proxy_order|
              puts
              puts "Proxy Order #{proxy_order.id}"
              puts "Canceled at #{proxy_order.canceled_at}"
              puts "Last updated at #{proxy_order.updated_at}"
              puts "Placed at #{proxy_order.placed_at}"
              puts "Confirmed at #{proxy_order.confirmed_at}"

              puts
              puts "Order #{proxy_order.order_id} - #{proxy_order.order.number}"
              puts "Order is #{proxy_order.order.state} with total #{proxy_order.order.total}"
              proxy_order.order.payments.each do |payment|
                puts "Payment #{payment.id} with state #{payment.state}"
                puts "Amount #{payment.amount}"
                puts "Source #{payment.source_type} #{payment.source_id}"
                if payment.source_type == "Spree::CreditCard"
                  puts "Source #{payment.source.to_json}"
                end
                Spree::LogEntry.where(source_type: "Spree::Payment",
                                      source_id: payment.id).each do |log_entry|
                  puts "Log Entries found"
                  puts log_entry.details
                end
              end
            end
          end
        end
      end

      def request_order_cycle_id
        puts "Please input Order Cycle ID to debug"
        input = STDIN.gets.chomp
        exit if input.blank? || !Integer(input)
        Integer(input)
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
