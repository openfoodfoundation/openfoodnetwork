module OpenFoodNetwork
  class OrderAndDistributorReport

    def initialize(user, params = {}, render_table = false)
      @params = params
      @user = user
      @render_table = render_table

      @permissions = OpenFoodNetwork::Permissions.new(user)
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
      @permissions.visible_orders.complete.not_state(:canceled).search(@params[:q])
    end

    def table
      return [] unless @render_table

      orders = search.result

      # If empty array is passed in, the where clause will return all line_items, which is bad
      orders_with_hidden_details =
        @permissions.editable_orders.empty? ? orders : orders.where('id NOT IN (?)', @permissions.editable_orders)

      orders.select{ |order| orders_with_hidden_details.include? order }.each do |order|
        # TODO We should really be hiding customer code here too, but until we
        # have an actual association between order and customer, it's a bit tricky
        order.bill_address.andand.assign_attributes(firstname: I18n.t('admin.reports.hidden'), lastname: "", phone: "", address1: "", address2: "", city: "", zipcode: "", state: nil)
        order.ship_address.andand.assign_attributes(firstname: I18n.t('admin.reports.hidden'), lastname: "", phone: "", address1: "", address2: "", city: "", zipcode: "", state: nil)
        order.assign_attributes(email: I18n.t('admin.reports.hidden'))
      end

      line_item_details orders
    end

    private

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
        order.created_at,
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
        order.payments.first.andand.payment_method.andand.name,
        order.distributor.andand.name,
        order.distributor.address.address1,
        order.distributor.address.city,
        order.distributor.address.zipcode,
        order.special_instructions
      ]
    end
  end
end
