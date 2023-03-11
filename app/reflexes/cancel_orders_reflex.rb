# frozen_string_literal: true

class CancelOrdersReflex < ApplicationReflex
  def confirm(params)
    OrdersBulkCancelService.new(params).call
    cable_ready.dispatch_event(name: "modal:close")
    # flash[:success] = Spree.t(:order_updated)
  end
end
