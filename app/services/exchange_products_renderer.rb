class ExchangeProductsRenderer
  def initialize(order_cycle, user)
    @order_cycle = order_cycle
    @user = user
  end

  def exchange_products(incoming, enterprise)
    if incoming
      products_for_incoming_exchange(enterprise)
    else
      products_for_outgoing_exchange
    end
  end

  private

  def products_for_incoming_exchange(enterprise)
    supplied_products(enterprise)
  end

  def supplied_products(enterprise)
    if @order_cycle.present? &&
       @order_cycle.prefers_product_selection_from_coordinator_inventory_only?
      enterprise.supplied_products.visible_for(@order_cycle.coordinator)
    else
      enterprise.supplied_products
    end
  end

  def products_for_outgoing_exchange
    products = []
    enterprises_for_outgoing_exchange.each do |enterprise|
      products.push( *supplied_products(enterprise).to_a )

      products.each do |product|
        unless product_supplied_to_order_cycle?(product)
          products.delete(product)
        end
      end
    end
    products
  end

  def product_supplied_to_order_cycle?(product)
    (product.variants.map(&:id) & incoming_exchanges_variants).any?
  end

  def incoming_exchanges_variants
    return @incoming_exchanges_variants if @incoming_exchanges_variants.present?

    @incoming_exchanges_variants = []
    visible_incoming_exchanges.each do |exchange|
      @incoming_exchanges_variants.push(
        *exchange.variants.merge(visible_incoming_variants(exchange)).map(&:id).to_a
      )
    end
    @incoming_exchanges_variants
  end

  def visible_incoming_exchanges
    OpenFoodNetwork::OrderCyclePermissions.
      new(@user, @order_cycle).
      visible_exchanges.
      by_enterprise_name.
      incoming
  end

  def visible_incoming_variants(exchange)
    if exchange.order_cycle.prefers_product_selection_from_coordinator_inventory_only?
      permitted_incoming_variants(exchange).visible_for(exchange.order_cycle.coordinator)
    else
      permitted_incoming_variants(exchange)
    end
  end

  def permitted_incoming_variants(exchange)
    OpenFoodNetwork::OrderCyclePermissions.new(@user, exchange.order_cycle).
      visible_variants_for_incoming_exchanges_from(exchange.sender)
  end

  def enterprises_for_outgoing_exchange
    enterprises = OpenFoodNetwork::OrderCyclePermissions.
      new(@user, @order_cycle)
      .visible_enterprises
    return enterprises if enterprises.empty?

    enterprises.includes(
      supplied_products: [:supplier, :variants, master: [:images]]
    )
  end
end
