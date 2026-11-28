# frozen_string_literal: true

# Adds the items in a customer's cart to one of their placed orders, instead of checking the cart
# out as a new order. The order keeps its number; its fees, taxes and payments are updated as when
# the customer changes it from the order page. The cart is emptied afterwards.
#
# Stock is taken as soon as the items are added. Check the cart's stock first (see
# Orders::CheckStockService): if an item can't be added anyway, nothing is added and the cart is
# kept as it was.
module Orders
  class AddCartToOrderService
    attr_reader :error

    def initialize(cart:, order:)
      @cart = cart
      @order = order
      @error = nil
    end

    def call
      @error = reason_not_addable
      return false if @error

      # requires_new: the controller calls this inside its own transaction (while locking the cart).
      # Without a savepoint of our own, the Rollback below would be ignored and the items added
      # before the failing one would stay in the order.
      @order.with_lock(requires_new: true) do
        unless add_cart_items
          @error = :insufficient_stock
          raise ActiveRecord::Rollback
        end

        update_fees_and_totals
        @cart.empty!
      end
      return false if @error

      AmendBackorderJob.perform_later(@order)
      true
    end

    private

    def reason_not_addable
      return :empty_cart if @cart.line_items.empty?

      :order_not_addable unless order_addable?
    end

    # The order must be the customer's own, from the same shop and order cycle as the cart, not a
    # subscription order (those are updated by the subscription), and open to additions.
    def order_addable?
      @cart.user.present? &&
        @order.user == @cart.user &&
        @order.distributor == @cart.distributor &&
        @order.order_cycle == @cart.order_cycle &&
        @order.proxy_order.nil? &&
        @order.additions_allowed?
    end

    # Adding an item takes its stock. The caller checks stock first, so this only
    # fails if an item sells out in between; then we stop and nothing is added.
    def add_cart_items
      @cart.line_items.includes(:variant).all? do |cart_item|
        variant = cart_item.variant
        # Use the shop's price and stock for the variant, as the cart did.
        variant_scoper.scope(variant)

        line_item = @order.contents.add(variant, cart_item.quantity, @order.shipment)
        line_item.errors.empty?
      end
    end

    # The same updates as when a customer changes their placed order (Spree::OrdersController#update).
    def update_fees_and_totals
      @order.recreate_all_fees!
      OrderManagement::Order::Updater.new(@order).update_voucher
      @order.update_payment_fees!
      @order.create_tax_charge!
    end

    def variant_scoper
      @variant_scoper ||= OpenFoodNetwork::ScopeVariantToHub.new(@order.distributor)
    end
  end
end
