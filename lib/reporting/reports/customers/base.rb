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
              first_name: order.billing_address.firstname,
              last_name: order.billing_address.lastname,
              billing_address: order.billing_address.address_and_city,
              email: order.email,
              phone: order.billing_address.phone,
              hub_id: order.distributor_id,
              shipping_method_id: order.shipping_method&.id,
            }
          end.values
        end

        # rubocop:disable Metrics/AbcSize
        def columns
          {
            first_name: proc { |orders| orders.first.billing_address.firstname },
            last_name: proc { |orders| orders.first.billing_address.lastname },
            billing_address: proc { |orders| orders.first.billing_address.address_and_city },
            email: proc { |orders| orders.first.email },
            phone: proc { |orders| orders.first.billing_address.phone },
            hub: proc { |orders| orders.first.distributor&.name },
            hub_address: proc { |orders| orders.first.distributor&.address&.address_and_city },
            shipping_method: proc { |orders| orders.first.shipping_method&.name },
            total_orders: proc { |orders| orders.count },
            total_incl_tax: proc { |orders| orders.sum(&:total) },
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
          if params[:q] &&
             params[:q][:completed_at_gt].present? &&
             params[:q][:completed_at_lt].present?
            orders.where("completed_at >= ? AND completed_at <= ?",
                         params[:q][:completed_at_gt],
                         params[:q][:completed_at_lt])
          else
            orders
          end
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

        def last_completed_order_date(orders)
          orders.max_by(&:completed_at)&.completed_at&.to_date
        end
      end
    end
  end
end
