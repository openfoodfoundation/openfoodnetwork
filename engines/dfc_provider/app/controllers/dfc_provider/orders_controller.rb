# frozen_string_literal: true

module DfcProvider
  class OrdersController < DfcProvider::ApplicationController
    include Pagy::Method

    DEFAULT_PER_PAGE = 25

    # Everything the graph reads through a line's variant: its price, its taxon,
    # its stock, and the product with its image and its other variants.
    VARIANT_INCLUDES = [:default_price, :primary_taxon, :stock_items,
                        { product: [:image, :variants] }].freeze

    before_action :check_enterprise

    # Lists the orders placed with this enterprise, as the same subjects that
    # `show` returns, all in one graph. Only the ReadOrders scope lets a
    # platform read them.
    #
    # `page` and `per_page` paginate the list: 25 orders per page unless the
    # client asks for another size, up to Pagy's app-wide limit of 100.
    # `updated_since` lets a client fetch only the orders that changed since
    # its last read.
    def index
      require_permission "ReadOrders"
      return head :bad_request if invalid_updated_since?

      _pagy, orders = pagy(orders_scope, limit: DEFAULT_PER_PAGE)
      render_dfc(*OrderBuilder.build_graph(orders))
    end

    def show
      dfc_order = OrderBuilder.build_with_lines(order)
      lines = dfc_order.lines
      offers = lines.map(&:offer)
      supplied_products = offers.map(&:offeredItem)

      sessions = [OrderBuilder.build_sale_session(order)]
      render_dfc(dfc_order, *lines, *offers, *supplied_products, *sessions)
    end

    def create
      return head :bad_request unless dfc_order

      @order = current_enterprise.distributed_orders.build(
        user: current_user,
        created_by: current_user,
        email: current_user.email,
        customer: current_user.customers.find_by(enterprise: current_enterprise),
      )

      if save_order(@order)
        subject = OrderBuilder.build(@order)
        response.headers["Location"] = subject.semanticId
        render_dfc(subject, status: :created)
      else
        render_error(@order)
      end
    end

    def update
      return head :bad_request unless dfc_order

      if save_order(order)
        render_dfc(OrderBuilder.build(order))
      else
        render_error(order)
      end
    end

    def destroy
      if order.allow_cancel?
        order.send_cancellation_email = false
        order.cancel!
        head :no_content
      else
        render json: { error: "Cannot cancel order in state '#{order.state}'" },
               status: :unprocessable_entity
      end
    end

    private

    def order
      @order ||= current_enterprise.distributed_orders.find(params[:id])
    end

    # The orders of the current enterprise, and only those: the enterprise is
    # resolved from the current user's enterprises. A cart that nobody has
    # placed yet isn't an order a partner can act on.
    #
    # A page holds at most 25 orders and each one brings its lines, whose
    # variants carry a price, a product, a taxon and their stock: they are
    # preloaded so that the number of queries doesn't grow with the page. The
    # stock itself is still counted per variant, by the stock quantifier.
    def orders_scope
      scope = current_enterprise.distributed_orders.complete
        .includes(:order_cycle, line_items: { variant: VARIANT_INCLUDES })
        .order(:id)
      return scope if updated_since.nil?

      scope.where(updated_at: updated_since..)
    end

    # `Time.zone.parse` returns nil for what it can't read and raises for a
    # date that doesn't exist, such as month 13. Both are a bad request.
    def updated_since
      Time.zone.parse(params[:updated_since].to_s) if params[:updated_since].present?
    rescue ArgumentError
      nil
    end

    def invalid_updated_since?
      params[:updated_since].present? && updated_since.nil?
    end

    def apply(ofn_order)
      OrderBuilder.apply(ofn_order, dfc_order, variant_scope: current_enterprise.variants)
    end

    # Applies the DFC order and writes it, recalculating everything that depends
    # on it. All of it happens in one transaction, so a payload we reject leaves
    # the order exactly as it was.
    #
    # The order record is saved before the payload is applied: the validation
    # that checks the products are available compares line items against the
    # distributor or order cycle, and only `distributor_id_changed?` or
    # `order_cycle_id_changed?` triggers it.
    def save_order(ofn_order)
      ActiveRecord::Base.transaction do
        ofn_order.save!
        raise ActiveRecord::Rollback unless apply(ofn_order)

        ofn_order.save!
        OrderBuilder.finalise(ofn_order, dfc_order)
        ofn_order.recreate_all_fees!
        ofn_order.create_tax_charge!
        ofn_order.update_order!
      end

      ofn_order.errors.empty?
    rescue ActiveRecord::RecordInvalid
      false
    end

    # `DfcIo.import` returns a bare object when the payload contains only one
    # subject, for example when a client just updates the order status.
    def dfc_order
      return @dfc_order if defined?(@dfc_order)

      @dfc_order = select_type(Array.wrap(import), "dfc-b:Order").first
    end

    def select_type(graph, semantic_type)
      graph.select { |i| i.semanticType == semantic_type }
    end

    def render_error(ofn_order)
      render json: { error: ofn_order.errors.full_messages.to_sentence },
             status: :unprocessable_entity
    end
  end
end
