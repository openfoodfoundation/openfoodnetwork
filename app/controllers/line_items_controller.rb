class LineItemsController < BaseController
  respond_to :json

  # Taken from Spree::Api::BaseController
  rescue_from ActiveRecord::RecordNotFound, :with => :not_found

  def bought
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

  def unauthorized
    render nothing: true, status: 401 and return
  end

  def not_found
    render nothing: true, status: 404 and return
  end

  def destroy_with_lock(item)
    order = item.order
    order.with_lock do
      item.destroy
      order.update_shipping_fees!
      order.update_payment_fees!
      order.update_distribution_charge!
      order.create_tax_charge!
    end
  end
end
