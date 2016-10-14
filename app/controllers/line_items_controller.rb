class LineItemsController < Spree::BaseController
  respond_to :json

  def destroy
    item = Spree::LineItem.find(params[:id])
    authorize! :destroy, item
    destroy_with_lock item
    respond_with(item)
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
      order.update_distribution_charge!
    end
  end
end
