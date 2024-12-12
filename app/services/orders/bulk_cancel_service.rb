# frozen_string_literal: true

module Orders
  class BulkCancelService
    def initialize(params, current_user)
      @order_ids = params[:bulk_ids]
      @current_user = current_user
      @send_cancellation_email = params[:send_cancellation_email]
      @restock_items = params[:restock_items]
    end

    def call
      # rubocop:disable Rails/FindEach # .each returns an array, .find_each returns nil
      editable_orders.where(id: @order_ids).each do |order|
        order.send_cancellation_email = @send_cancellation_email
        order.restock_items = @restock_items
        order.cancel
      end.tap { |orders| AmendBackorderJob.schedule_bulk_update_for(orders) }
      # rubocop:enable Rails/FindEach
    end

    private

    def editable_orders
      Permissions::Order.new(@current_user).editable_orders
    end
  end
end
