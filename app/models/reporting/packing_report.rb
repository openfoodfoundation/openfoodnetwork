# frozen_string_literal: true

module Reporting
  class PackingReport < Report
    def collection
      Spree::LineItem.includes(*line_item_includes).where(order_id: order_ids).uniq
    end

    def report_row(object)
      {
        order_id: object.order_id,
        hub: orders[object.order_id].distributor.name,
        customer_code: orders[object.order_id].customer.andand.code,
        first_name: orders[object.order_id].bill_address.firstname,
        last_name: orders[object.order_id].bill_address.lastname,
        supplier: object.product.supplier.name,
        product: object.product.name,
        variant: object.full_name,
        quantity: object.quantity,
        is_temperature_controlled: object.product.shipping_category.andand.temperature_controlled ? "Yes" : "No"
      }
    end

    def ordering
      [:hub, :order_id, :product]
    end

    def summary_group
      :order_id
    end

    def summary_row
      { title: 'TOTAL', sum: [:quantity] }
    end

    def hide_columns
      [:order_id]
    end

    private

    def permissions
      Permissions::Order.new(current_user, ransack_params)
    end

    def orders
      @orders ||= permissions.visible_orders.
        complete.not_state(:canceled).
        includes(:bill_address, :distributor, :customer).
        ransack(ransack_params).result.index_by(&:id)
    end

    def order_ids
      orders.keys
    end

    def line_item_includes
      [{
        option_values: :option_type,
        variant: { product: [:supplier, :shipping_category] }
      }]
    end
  end
end
