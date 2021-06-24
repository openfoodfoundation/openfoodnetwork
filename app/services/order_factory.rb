# frozen_string_literal: true

require 'open_food_network/scope_variant_to_hub'

# Builds orders based on a set of attributes
# There are some idiosyncracies in the order creation process,
# and it is nice to have them dealt with in one place.

class OrderFactory
  def initialize(attrs, opts = {})
    @attrs = attrs.with_indifferent_access
    @opts = opts.with_indifferent_access
  end

  def create
    create_order
    set_user
    build_line_items
    set_addresses
    create_shipment
    set_shipping_method
    create_payment

    @order
  end

  private

  attr_reader :attrs, :opts

  def customer
    @customer ||= Customer.find(attrs[:customer_id])
  end

  def shop
    @shop ||= Enterprise.find(attrs[:distributor_id])
  end

  def create_order
    @order = Spree::Order.create!(create_attrs)
  end

  def create_attrs
    create_attrs = attrs.slice(:customer_id, :order_cycle_id, :distributor_id)
    create_attrs[:email] = customer.email
    create_attrs
  end

  def build_line_items
    attrs[:line_items].each do |li|
      next unless variant = Spree::Variant.find_by(id: li[:variant_id])

      scoper.scope(variant)
      li[:quantity] = stock_limited_quantity(variant.on_demand, variant.on_hand, li[:quantity])
      li[:price] = variant.price
      build_item_from(li)
    end
  end

  def build_item_from(attrs)
    @order.line_items.build(
      attrs.merge(skip_stock_check: opts[:skip_stock_check])
    )
  end

  def set_user
    @order.update_attribute(:user_id, customer.user_id)
  end

  def set_addresses
    @order.update(attrs.slice(:bill_address_attributes, :ship_address_attributes))
  end

  def create_shipment
    @order.create_proposed_shipments
  end

  def set_shipping_method
    @order.select_shipping_method(attrs[:shipping_method_id])
  end

  def create_payment
    @order.recreate_all_fees!
    @order.payments.create(payment_method_id: attrs[:payment_method_id],
                           amount: @order.reload.total)
  end

  def stock_limited_quantity(variant_on_demand, variant_on_hand, requested)
    return requested if opts[:skip_stock_check] || variant_on_demand

    [variant_on_hand, requested].min
  end

  def scoper
    @scoper ||= OpenFoodNetwork::ScopeVariantToHub.new(shop)
  end
end
