# frozen_string_literal: true

module Reporting
  module Reports
    module Customers
      class Base < ReportTemplate
        def query_result
          filter Spree::Order.managed_by(@user)
            .distributed_by_user(@user)
            .complete.not_state(:canceled)
            .order(:id)
        end

        def filter(orders)
          filter_to_completed_at filter_to_distributor filter_to_order_cycle orders
        end

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
      end
    end
  end
end
