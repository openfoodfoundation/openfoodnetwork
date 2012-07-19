module OpenFoodWeb
  class OrderAndDistributorReport

    def initialize orders
      @orders = orders
    end

    def header
      ["Order date", "Order Id", "Name","Email", "SKU", "Item cost", "Quantity", "Cost", "Shipping cost", "Distributor", "Distributor address", "Distributor city", "Distributor postcode"]
    end

    def table
      order_and_distributor_details = []
      @orders.each do |order|
        order.line_items.each do |line_item|
          order_and_distributor_details << [order.created_at, order.id, order.bill_address.full_name, order.user.email,
            line_item.product.sku, line_item.product.name, line_item.quantity, line_item.price * line_item.quantity, line_item.itemwise_shipping_cost,
            order.distributor.name, order.distributor.pickup_address.address1, order.distributor.pickup_address.city, order.distributor.pickup_address.zipcode ]
        end
      end
      order_and_distributor_details
    end
  end
end
