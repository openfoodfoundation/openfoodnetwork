# frozen_string_literal: true

require 'open_food_network/order_cycle_permissions'

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

  def exchange_variants(incoming, enterprise)
    variants_relation = Spree::Variant.
      where(product_id: exchange_products(incoming, enterprise).select(&:id))

    filter_visible(variants_relation)
  end

  private

  def products_for_incoming_exchange(enterprise)
    supplied_products(enterprise.id)
  end

  def supplied_products(enterprises_query_matcher)
    products_relation = Spree::Product.where(supplier_id: enterprises_query_matcher).order(:name)

    filter_visible(products_relation)
  end

  def filter_visible(relation)
    if @order_cycle.present? &&
       @order_cycle.prefers_product_selection_from_coordinator_inventory_only?
      relation = relation.visible_for(@order_cycle.coordinator)
    end

    relation
  end

  def products_for_outgoing_exchange
    supplied_products(enterprises_for_outgoing_exchange.select(:id)).
      includes(:variants).
      where("spree_variants.id": incoming_exchanges_variants)
  end

  def incoming_exchanges_variants
    return @incoming_exchanges_variants if @incoming_exchanges_variants.present?

    @incoming_exchanges_variants = []
    visible_incoming_exchanges.each do |incoming_exchange|
      @incoming_exchanges_variants.push(
        *incoming_exchange.variants.merge(
          visible_incoming_variants(incoming_exchange.sender)
        ).map(&:id).to_a
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

  def visible_incoming_variants(incoming_exchange_sender)
    variants_relation = permitted_incoming_variants(incoming_exchange_sender)

    if @order_cycle.prefers_product_selection_from_coordinator_inventory_only?
      variants_relation = variants_relation.visible_for(@order_cycle.coordinator)
    end

    variants_relation
  end

  def permitted_incoming_variants(incoming_exchange_sender)
    OpenFoodNetwork::OrderCyclePermissions.
      new(@user, @order_cycle).
      visible_variants_for_incoming_exchanges_from(incoming_exchange_sender)
  end

  def enterprises_for_outgoing_exchange
    enterprises = OpenFoodNetwork::OrderCyclePermissions.
      new(@user, @order_cycle)
      .visible_enterprises
    return enterprises if enterprises.empty?

    enterprises.includes(
      supplied_products: [:supplier, :variants, :image]
    )
  end
end
