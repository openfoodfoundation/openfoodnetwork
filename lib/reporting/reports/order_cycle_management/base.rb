# frozen_string_literal: true

module Reporting
  module Reports
    module OrderCycleManagement
      class Base < ReportTemplate
        def default_params
          {
            q: {
              completed_at_gt: 1.month.ago.beginning_of_day,
              completed_at_lt: 1.day.from_now.beginning_of_day
            }
          }
        end

        def search
          Spree::Order.
            finalized.
            not_state(:canceled).
            distributed_by_user(@user).
            managed_by(@user).
            ransack(ransack_params)
        end

        # This result is used in _order_cucle_management.html so caching it
        def query_result
          @query_result ||= orders
        end

        def orders
          search_result = search.result.order(:completed_at)
          orders = OutstandingBalance.new(search_result).query.select('spree_orders.*')

          filter(orders)
        end

        def filter(orders)
          filter_to_payment_method filter_to_shipping_method filter_to_order_cycle orders
        end

        private

        def filter_to_payment_method(orders)
          if params[:payment_method_in].present?
            orders
              .joins(payments: :payment_method)
              .where(spree_payments: { payment_method_id: params[:payment_method_in] })
          else
            orders
          end
        end

        def filter_to_shipping_method(orders)
          if params[:shipping_method_in].present?
            orders
              .joins(shipments: :shipping_rates)
              .where(spree_shipping_rates: {
                       selected: true,
                       shipping_method_id: params[:shipping_method_in]
                     })
          else
            orders
          end
        end

        def filter_to_order_cycle(orders)
          if params[:order_cycle_id].present?
            orders.where(order_cycle_id: params[:order_cycle_id])
          else
            orders
          end
        end

        def customer_code(email)
          customer = Customer.where(email: email).first
          customer.nil? ? "" : customer.code
        end
      end
    end
  end
end
