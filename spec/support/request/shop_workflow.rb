module ShopWorkflow
  def wait_for_cart
    first("#cart").click
    within '.cart-dropdown' do
      expect(page).to_not have_link "Updating cart..."
    end
  end

  def edit_cart
    wait_for_cart
    within '.cart-dropdown' do
      expect(page).to have_link "Edit your cart"
    end
    first("a.add_to_cart").click
  end

  def have_price(price)
    have_selector ".price", text: price
  end

  def add_enterprise_fee(enterprise_fee)
    order_cycle.exchanges.outgoing.first.enterprise_fees << enterprise_fee
  end

  def set_order(order)
    allow_any_instance_of(ApplicationController).to receive(:session).and_return(order_id: order.id, access_token: order.token)
  end

  def add_product_to_cart(order, product, quantity: 1)
    cart_service = CartService.new(order)
    cart_service.populate(variants: { product.variants.first.id => quantity })

    # Recalculate fee totals
    order.update_distribution_charge!
  end

  def toggle_accordion(name)
    find("dd a", text: name).click
  end

  def add_variant_to_order_cycle(exchange, variant)
    ensure_supplier_exchange(exchange, variant.product.supplier)
    exchange.variants << variant
  end

  def set_order_cycle(order, order_cycle)
    order.update_attribute(:order_cycle, order_cycle)
  end

  private

  # An order cycle needs an incoming exchange for a supplier
  # before having its products. Otherwise the data will be inconsistent and
  # and not all needed enterprises are loaded into the shop page.
  def ensure_supplier_exchange(exchange, supplier)
    oc = exchange.order_cycle
    if oc.exchanges.from_enterprise(supplier).incoming.empty?
      create(:exchange, order_cycle: oc, incoming: true,
                        sender: supplier, receiver: oc.coordinator)
    end
  end
end
