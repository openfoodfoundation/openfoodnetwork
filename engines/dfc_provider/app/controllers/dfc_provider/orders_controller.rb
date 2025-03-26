# frozen_string_literal: true

# Create and update orders
module DfcProvider
  class OrdersController < DfcProvider::ApplicationController
    before_action :check_enterprise

    # POST /api/dfc/enterprises/{enterprise_id}/orders
    def create
      graph = import
      dfc_order = select_type(graph, "dfc-b:Order").first if graph

      return head :bad_request unless dfc_order

      order = current_enterprise.distributed_orders.build(created_by: current_user)

      # Customer E-Mail can't be blank

      # rubocop:disable Style/GuardClause
      if order.save && OrderBuilder.apply(order, dfc_order, graph)
        subject = OrderBuilder.build(order)
        render json: DfcIo.export(subject), status: :created
      else
        render json: {error: order.errors.full_messages.to_sentence}, status: :unprocessable_entity
      end
      # rubocop:enable Style/GuardClause
    end

    # This is similar to DfcCatalog#select_type. Consider moving to a new DfcGraph class.
    def select_type(graph, semantic_type)
      graph.select { |i| i.semanticType == semantic_type }
    end
  end
end
