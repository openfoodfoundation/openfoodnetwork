include Spree::ReportsHelper

module OpenFoodNetwork
  class OrderAndDistributorReport
    attr_reader :params
    def initialize user, params, orders = nil
      @user = user
      @params = params
      @orders = orders
    end

    def header
      [I18n.t(:report_header_order_date),
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
        I18n.t(:report_header_shipping_instructions)]
    end

    def search
      permissions.visible_orders.complete.not_state(:canceled).search(params[:q])
    end

    def table_items
      orders = search.result

      line_items = permissions.visible_line_items.merge(Spree::LineItem.where(order_id: orders))
      line_items = line_items.preload([:order, :product])
      line_items = line_items.supplied_by_any(params[:supplier_id_in]) if params[:supplier_id_in].present?

      line_items
    end


    def table
      order_and_distributor_details = []

      @orders.each do |order|
        order.line_items.each do |line_item|
          order_and_distributor_details << [order.created_at, order.id,
            order.bill_address.full_name, order.email, order.bill_address.phone, order.bill_address.city,
            line_item.product.sku, line_item.product.name, line_item.options_text, line_item.quantity, line_item.max_quantity, line_item.price * line_item.quantity, line_item.distribution_fee,
            order.payments.first.andand.payment_method.andand.name,
            order.distributor.andand.name, order.distributor.address.address1, order.distributor.address.city, order.distributor.address.zipcode, order.special_instructions ]
        end
      end

      order_and_distributor_details
    end



    private

    def permissions
      return @permissions unless @permissions.nil?
      @permissions = OpenFoodNetwork::Permissions.new(@user)
    end
  end
end
