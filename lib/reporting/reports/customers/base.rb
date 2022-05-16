# frozen_string_literal: true

module Reporting
  module Reports
    module Customers
      class Base < ReportTemplate
        def query_result
          filter Spree::Order.managed_by(@user)
            .distributed_by_user(@user)
            .complete.not_state(:canceled)
        end

        def filter(orders)
          filter_to_supplier filter_to_distributor filter_to_order_cycle orders
        end

        def filter_to_supplier(orders)
          if params[:supplier_id].to_i > 0
            orders.select do |order|
              order.line_items.includes(:product)
                .where("spree_products.supplier_id = ?", params[:supplier_id].to_i)
                .references(:product)
                .count
                .positive?
            end
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
