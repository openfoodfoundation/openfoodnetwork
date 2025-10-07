# frozen_string_literal: true

module Reporting
  module Reports
    module Customers
      class Base < ReportTemplate
        def query_result
          filter(Spree::Order.managed_by(@user)
            .distributed_by_user(@user)
            .complete.not_state(:canceled)
            .order(:id))
            .group_by do |order|
            {
              customer_id: order.customer_id || order.email,
              hub_id: order.distributor_id,
            }
          end.values
        end

        # rubocop:disable Metrics/AbcSize
        def columns
          {
            first_name: proc { |orders| last_completed_order(orders).billing_address.firstname },
            last_name: proc { |orders| last_completed_order(orders).billing_address.lastname },
            billing_address: proc { |orders|
                               last_completed_order(orders).billing_address.address_and_city
                             },
            email: proc { |orders| last_completed_order(orders).email },
            phone: proc { |orders| last_completed_order(orders).billing_address.phone },
            hub: proc { |orders| last_completed_order(orders).distributor&.name },
            hub_address: proc { |orders|
                           last_completed_order(orders).distributor&.address&.address_and_city
                         },
            shipping_method: proc { |orders| last_completed_order(orders).shipping_method&.name },
            total_orders: proc { |orders| orders.count },
            total_incl_tax: proc { |orders| orders.map(&:total).sum(&:to_f) },
            last_completed_order_date: proc { |orders| last_completed_order_date(orders) },
          }
        end
        # rubocop:enable Metrics/AbcSize

        def filter(orders)
          filter_to_completed_at filter_to_distributor filter_to_order_cycle orders
        end

        def skip_duplicate_rows?
          true
        end

        private

        def filter_to_completed_at(orders)
          min = params.dig(:q, :completed_at_gt).presence&.in_time_zone
          max = params.dig(:q, :completed_at_lt).presence&.in_time_zone

          return orders if min.nil? && max.nil?

          orders.where(completed_at: [min..max])
        end

        def filter_to_distributor(orders)
          if params[:distributor_id].to_i > 0
            orders.where(distributor_id: params[:distributor_id])
          else
            orders
          end
        end

        def filter_to_order_cycle(orders)
          if params[:order_cycle_id].to_i > 0
            orders.where(order_cycle_id: params[:order_cycle_id])
          else
            orders
          end
        end

        def last_completed_order(orders)
          orders.max_by(&:completed_at)
        end

        def last_completed_order_date(orders)
          last_completed_order(orders).completed_at&.to_date
        end
      end
    end
  end
end
