# frozen_string_literal: true

# Create and update orders
module DfcProvider
  class OrdersController < DfcProvider::ApplicationController
    before_action :check_enterprise

    # POST /api/dfc/enterprises/{enterprise_id}/orders
    def create
      # The importer requires an ID, so here's a dummy:
      object = JSON.parse(request.body.read)&.merge(
        '@id' => 'http://dummy'
      )
      order_params = DfcIo.import(object)

      return head :bad_request unless order_params

      order = current_enterprise.distributed_orders.build(user: current_user)

      # rubocop:disable Style/GuardClause
      if order.save
        subject = OrderBuilder.build(order)
        render json: DfcIo.export(subject), status: :created
      end
      # rubocop:enable Style/GuardClause
    end
  end
end
