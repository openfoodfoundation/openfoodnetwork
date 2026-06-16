# frozen_string_literal: true

module DfcProvider
  class OrdersController < DfcProvider::ApplicationController
    before_action :check_enterprise

    def show
      dfc_order = OrderBuilder.build(order)
      lines = OrderBuilder.build_order_lines(dfc_order, order.line_items)
      offers = lines.map(&:offer)
      catalog_items = offers.map(&:offeredItem)

      sessions = [build_sale_session(order)]
      render_dfc(dfc_order, *lines, *offers, *catalog_items, *sessions)
    end

    def create
      graph = import
      dfc_order = select_type(graph, "dfc-b:Order").first if graph

      return head :bad_request unless dfc_order

      @order = current_enterprise.distributed_orders.build(
        user: current_user,
        created_by: current_user,
        email: current_user.email,
        customer: current_user.customers.find_by(enterprise: current_enterprise),
      )

      if @order.save && OrderBuilder.apply(@order, dfc_order)
        subject = OrderBuilder.build(@order)
        render json: DfcIo.export(subject), status: :created
      else
        render json: { error: @order.errors.full_messages.to_sentence },
               status: :unprocessable_entity
      end
    end

    private

    def order
      @order ||= current_enterprise.distributed_orders.find(params[:id])
    end

    def select_type(graph, semantic_type)
      graph.select { |i| i.semanticType == semantic_type }
    end

    def build_sale_session(order)
      SaleSessionBuilder.build(order.order_cycle).tap do |session|
        session.semanticId = "/api/dfc/SalesSession/#"
      end
    end
  end
end
