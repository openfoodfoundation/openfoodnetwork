# frozen_string_literal: true

module DfcProvider
  class OrdersController < DfcProvider::ApplicationController
    before_action :check_enterprise

    def show
      dfc_order = OrderBuilder.build(order)
      lines = OrderBuilder.build_order_lines(dfc_order, order.line_items)
      offers = lines.map(&:offer)
      supplied_products = offers.map(&:offeredItem)

      sessions = [build_sale_session(order)]
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

    def build_sale_session(order)
      SaleSessionBuilder.build(order.order_cycle).tap do |session|
        session.semanticId = "#{enterprise_url(current_enterprise.id)}/SalesSession/#"
      end
    end
  end
end
