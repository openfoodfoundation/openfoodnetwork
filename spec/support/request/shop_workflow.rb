module ShopWorkflow
  def select_distributor
    visit "/"
    click_link distributor.name
  end

  # These methods are naughty and write to the DB directly
  # Because loading the whole Angular app is slow
  def select_order_cycle
    #exchange = Exchange.find(order_cycle.exchanges.to_enterprises(distributor).outgoing.first.id) 
    #visit "/shop"
    #select exchange.pickup_time, from: "order_cycle_id"
    order.update_attribute :order_cycle, order_cycle
  end

  def add_product_to_cart
    #fill_in "variants[#{product.master.id}]", with: product.master.on_hand - 1
    #first("form.custom > input.button.right").click 
    create(:line_item, variant: product.master, order: order)
  end
end
