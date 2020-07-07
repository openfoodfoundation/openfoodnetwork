module ShopWorkflow
  # If a spec uses `within` but we want to check something outside of that
  # scope, we can search from the body element instead.
  def find_body
    page.all("body").first || page.find(:xpath, "ancestor::body")
  end

  def wait_for_cart
    # Wait for debounce
    #
    # The auto-submit on these specific form elements (add to cart) now has a small built-in
    # waiting period before submitting the data...
    sleep 0.6

    within find_body do
      # We ignore visibility in case the cart dropdown is not open.
      within '.cart-sidebar', visible: false do
        expect(page).to_not have_link "Updating cart...", visible: false
      end
    end
  end

  def edit_cart
    wait_for_cart
    toggle_cart
    within '.cart-sidebar' do
      expect(page).to have_link I18n.t('shared.menu.cart_sidebar.edit_cart')
    end
    first("a.edit-cart").click
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

  # Add an item to the cart
  #
  # At the moment, the user enters the quantity into an input field.
  # But with the coming mobile-friendly UX, the user will click a button to
  # add an item, hence the naming.
  #
  # This is temporary code. The duplication will be removed by the mobile
  # product listings feature. This has been backported to avoid merge
  # conflicts and to make the current build more stable.
  def click_add_to_cart(variant = nil, quantity = 1)
    within_variant(variant) do
      input = page.find("input")
      new_quantity = input.value.to_i + quantity
      fill_in input[:name], with: new_quantity
    end
    wait_for_cart
  end

  def click_remove_from_cart(variant = nil, quantity = 1)
    within_variant(variant) do
      input = page.find("input")
      new_quantity = input.value.to_i - quantity
      fill_in input[:name], with: new_quantity
    end
    wait_for_cart
  end

  def click_add_bulk_to_cart(variant = nil, quantity = 1)
    within_variant(variant) do
      input = page.find("input")
      new_quantity = input.value.to_i + quantity
      fill_in input[:name], with: new_quantity
    end
    wait_for_cart
  end

  def click_add_bulk_max_to_cart(variant = nil, quantity = 1)
    within_variant(variant) do
      input = page.find(:field, "variant_attributes[#{variant.id}][max_quantity]")
      new_quantity = input.value.to_i + quantity
      fill_in input[:name], with: new_quantity
    end
    wait_for_cart
  end

  def within_variant(variant = nil)
    selector = variant ? "#variant-#{variant.id}" : ".variants"
    expect(page).to have_selector selector
    within(selector) do
      yield
    end
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
