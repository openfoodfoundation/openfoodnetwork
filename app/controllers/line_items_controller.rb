class LineItemsController < BaseController
  respond_to :json

  def index
    respond_with bought_items, each_serializer: Api::LineItemSerializer
  end

  def destroy
    item = Spree::LineItem.find(params[:id])
    authorize! :destroy, item
    destroy_with_lock item
    respond_with(item)
  end

  private

  # List all items the user already ordered in the current order cycle
  def bought_items
    return [] unless current_order_cycle && spree_current_user && current_distributor
    current_order_cycle.items_bought_by_user(spree_current_user, current_distributor)
  end

  # Override default which just redirects
  # See Spree::BaseController and Spree::Core::ControllerHelpers::Auth
  def unauthorized
    render text: '', status: 403
  end

  def destroy_with_lock(item)
    order = item.order
    order.with_lock do
      item.destroy
      order.update_shipping_fees!
      order.update_distribution_charge!
    end
  end
end
