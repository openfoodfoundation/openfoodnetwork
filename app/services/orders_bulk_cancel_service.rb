# frozen_string_literal: true

class OrdersBulkCancelService
  def initialize(params)
    @order_ids = params[:order_ids]
    @send_cancellation_email = params[:send_cancellation_email]
    @restock_items = params[:restock_items]
  end

  def call
    Spree::Order.where(id: @order_ids).find_each do |order|
      order.send_cancellation_email = @send_cancellation_email
      order.restock_items = @restock_items
      order.cancel
    end
  end
end
