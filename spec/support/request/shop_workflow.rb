module ShopWorkflow
  def add_to_cart
    wait_until_enabled 'input.add_to_cart'
    first("input.add_to_cart:not([disabled='disabled'])").click
  end

  def have_price(price)
    have_selector ".price", text: price
  end

  def add_enterprise_fee(enterprise_fee)
    order_cycle.exchanges.outgoing.first.enterprise_fees << enterprise_fee
  end

  def set_order(order)
    ApplicationController.any_instance.stub(:session).and_return({order_id: order.id, access_token: order.token})
  end

  def add_product_to_cart
    create(:line_item, variant: product.master, order: order)
    order.reload

    # Recalculate totals
    order.save!
    order.update_distribution_charge!
  end

  def toggle_accordion(name)
    find("dd a", text: name).trigger "click"
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
