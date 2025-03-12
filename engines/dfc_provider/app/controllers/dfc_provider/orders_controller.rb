# frozen_string_literal: true

# Create and update orders
module DfcProvider
  class OrdersController < DfcProvider::ApplicationController
    before_action :check_enterprise

    # POST /api/dfc/enterprises/{enterprise_id}/orders
    def create
      if current_enterprise.distributed_orders.create user: current_user
        head :created
      end
    end
  end
end
