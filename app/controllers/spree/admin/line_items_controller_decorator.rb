Spree::Admin::LineItemsController.class_eval do
  prepend_before_filter :load_order, except: :index

  respond_to :json

  def index
    respond_to do |format|
      format.json do
        order_params = params[:q].andand.delete :order
        orders = OpenFoodNetwork::Permissions.new(spree_current_user).editable_orders.ransack(order_params).result
        line_items = OpenFoodNetwork::Permissions.new(spree_current_user).editable_line_items.where(order_id: orders).ransack(params[:q])
        render_as_json line_items.result.reorder('order_id ASC, id ASC')
      end
    end
  end

  private

    def load_order
      @order = Spree::Order.find_by_number!(params[:order_id])
      authorize! :update, @order
    end
end
