include Spree::ReportsHelper

module OpenFoodNetwork
  class OrderAndDistributorReport
    attr_reader :params
    def initialize user, params = {}, orders = nil
      @user = user
      @params = params
      @orders = orders
    end

    def header
      ["Order date", "Order Id",
       "Customer Name","Customer Email", "Customer Phone", "Customer City",
       "SKU", "Item name", "Variant", "Quantity", "Max Quantity", "Cost", "Shipping cost",
       "Payment method",
       "Distributor", "Distributor address", "Distributor city", "Distributor postcode", "Shipping instructions"]
    end

    def search
      permissions.visible_orders.complete.not_state(:canceled).search(params[:q])
    end

    def table_items
      orders = search.result

      # FIXME - Maybe we just need orders instead of line_items?
      line_items = permissions.visible_line_items.merge(Spree::LineItem.where(order_id: orders))
      line_items = line_items.preload([:order, :variant, :product])
      line_items = line_items.supplied_by_any(params[:q][:supplier_id_in]) if params[:q].andand[:supplier_id_in].present?

      # If empty array is passed in, the where clause will return all line_items, which is bad
      line_items_with_hidden_details =
        permissions.editable_line_items.empty? ? line_items : line_items.where('"spree_line_items"."id" NOT IN (?)', permissions.editable_line_items)

      line_items.select{ |li| line_items_with_hidden_details.include? li }.each do |line_item|
        # TODO We should really be hiding customer code here too, but until we
        # have an actual association between order and customer, it's a bit tricky
        line_item.order.bill_address.andand.assign_attributes(firstname: "HIDDEN", lastname: "", phone: "", address1: "", address2: "", city: "", zipcode: "", state: nil)
        line_item.order.ship_address.andand.assign_attributes(firstname: "HIDDEN", lastname: "", phone: "", address1: "", address2: "", city: "", zipcode: "", state: nil)
        line_item.order.assign_attributes(email: "HIDDEN")
      end

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
