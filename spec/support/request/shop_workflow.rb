module ShopWorkflow
  def select_distributor
    # If no order cycles are available this is much faster
    visit "/"
    click_link distributor.name
  end

  # These methods are naughty and write to the DB directly
  # Because loading the whole Angular app is slow
  def select_order_cycle
    exchange = Exchange.find(order_cycle.exchanges.to_enterprises(distributor).outgoing.first.id) 
    exchange.variants << product.master
    order.update_attribute :order_cycle, order_cycle
  end

  def add_product_to_cart
    create(:line_item, variant: product.master, order: order)
  end

  def toggle_accordion(name)
    find("dd a", text: name.upcase).click
  end
end
