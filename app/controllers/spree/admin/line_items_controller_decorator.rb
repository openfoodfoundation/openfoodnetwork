Spree::Admin::LineItemsController.class_eval do
  private

    def load_order
      @order = Spree::Order.find_by_number!(params[:order_id])
      authorize! :update, @order
    end
end
