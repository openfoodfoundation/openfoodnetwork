Spree::Admin::LineItemsController.class_eval do
  prepend_before_filter :load_order, except: :index

  respond_to :json

  def index
    respond_to do |format|
      format.json do
        search = OpenFoodNetwork::Permissions.new(spree_current_user).editable_line_items.ransack(params[:q])
        render_as_json search.result.sort_by(&:order_id)
      end
    end
  end

  private

    def load_order
      @order = Spree::Order.find_by_number!(params[:order_id])
      authorize! :update, @order
    end
end
