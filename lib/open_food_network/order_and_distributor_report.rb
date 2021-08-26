# frozen_string_literal: true

module OpenFoodNetwork
  class OrderAndDistributorReport
    def initialize(user, params = {}, render_table = false)
      @params = params
      @user = user
      @render_table = render_table

      @permissions = ::Permissions::Order.new(user, @params[:q])
    end

    def header
      [
        I18n.t(:report_header_order_date),
        I18n.t(:report_header_order_id),
        I18n.t(:report_header_customer_name),
        I18n.t(:report_header_customer_email),
        I18n.t(:report_header_customer_phone),
        I18n.t(:report_header_customer_city),
        I18n.t(:report_header_sku),
        I18n.t(:report_header_item_name),
        I18n.t(:report_header_variant),
        I18n.t(:report_header_quantity),
        I18n.t(:report_header_max_quantity),
        I18n.t(:report_header_cost),
        I18n.t(:report_header_shipping_cost),
        I18n.t(:report_header_payment_method),
        I18n.t(:report_header_distributor),
        I18n.t(:report_header_distributor_address),
        I18n.t(:report_header_distributor_city),
        I18n.t(:report_header_distributor_postcode),
        I18n.t(:report_header_shipping_method),
        I18n.t(:report_header_shipping_instructions)
      ]
    end

    def search
      @permissions.visible_orders.select("DISTINCT spree_orders.*").
        complete.not_state(:canceled).
        ransack(@params[:q])
    end

    def table
      return [] unless @render_table

      orders = search.result

      orders.select{ |order| orders_with_hidden_details(orders).include? order }.each do |order|
        OrderDataMasker.new(order).call
      end

      line_item_details orders
    end

    private

    def orders_with_hidden_details(orders)
      # If empty array is passed in, the where clause will return all line_items, which is bad
      if @permissions.editable_orders.empty?
        orders
      else
        orders.
          where('spree_orders.id NOT IN (?)',
                @permissions.editable_orders.select(&:id))
      end
    end

    def line_item_details(orders)
      order_and_distributor_details = []

      orders.each do |order|
        order.line_items.each do |line_item|
          order_and_distributor_details << row_for(line_item, order)
        end
      end

      order_and_distributor_details
    end

    # Returns a row with the data to display for the specified line_item and
    # its order
    #
    # @param line_item [Spree::LineItem]
    # @param order [Spree::Order]
    # @return [Array]
    def row_for(line_item, order)
      [
        order.completed_at.strftime("%F %T"),
        order.id,
        order.bill_address.full_name,
        order.email,
        order.bill_address.phone,
        order.bill_address.city,
        line_item.product.sku,
        line_item.product.name,
        line_item.options_text,
        line_item.quantity,
        line_item.max_quantity,
        line_item.price * line_item.quantity,
        line_item.distribution_fee,
        order.payments.first&.payment_method&.name,
        order.distributor&.name,
        order.distributor.address.address1,
        order.distributor.address.city,
        order.distributor.address.zipcode,
        order.shipping_method.name,
        order.special_instructions
      ]
    end
  end
end
