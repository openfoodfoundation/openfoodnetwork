# frozen_string_literal: true

# Create and update orders
module DfcProvider
  class OrdersController < DfcProvider::ApplicationController
    before_action :check_enterprise

    # POST /api/dfc/enterprises/{enterprise_id}/orders
    def create
      order = current_enterprise.distributed_orders.build(created_by: current_user)

      if order.save
        subject = OrderBuilder.build(order)
        render json: DfcIo.export(subject), status: :created
      end
    end
  end
end
