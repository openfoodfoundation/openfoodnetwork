module ShopWorkflow
  def set_order(order)
    ApplicationController.any_instance.stub(:session).and_return({order_id: order.id, access_token: order.token})
  end

  def add_product_to_cart
    create(:line_item, variant: product.master, order: order)
  end

  def toggle_accordion(name)
    find("dd a", text: name).click
  end

  def add_product_to_order_cycle(exchange, product)
    exchange.variants << product.master
  end

  def add_product_and_variant_to_order_cycle(exchange, product, variant)
    exchange.variants << product.master
    exchange.variants << variant 
  end
  
  def set_order_cycle(order, order_cycle)
    order.update_attribute(:order_cycle, order_cycle)
  end
end
