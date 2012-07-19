module OpenFoodWeb
  class OrderAndDistributorReport

    def initialize orders
      @orders = orders
    end

    def header
      ["Order date", "Order Id",
          "Customer Name","Customer Email", "Customer Phone", "Customer City",
          "SKU", "Item name", "Variant", "Quantity", "Cost", "Shipping cost",
          "Payment method",
          "Distributor", "Distributor address", "Distributor city", "Distributor postcode"]
    end

    def table
      order_and_distributor_details = []
      @orders.each do |order|
        order.line_items.each do |line_item|
          order_and_distributor_details << [order.created_at, order.id,
            order.bill_address.full_name, order.user.email, order.bill_address.phone, order.bill_address.city,
            line_item.product.sku, line_item.product.name, line_item.variant.name, line_item.quantity, line_item.price * line_item.quantity, line_item.itemwise_shipping_cost,
            order.payments.first.payment_method.name,
            order.distributor.name, order.distributor.pickup_address.address1, order.distributor.pickup_address.city, order.distributor.pickup_address.zipcode ]
        end
      end
      order_and_distributor_details
    end
  end
end
