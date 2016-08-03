class Spree::LineItemsController < ApplicationController
  skip_authorization_check
  def destroy
    item = Spree::LineItem.find(params[:id])
    order = item.order
    return unauthorized unless order.user_id == spree_current_user.andand.id
    destroy_with_lock item if order.order_cycle.open?
    respond_to_destroy item
  end

  def unauthorized
    redirect_to '/unauthorized'
  end

  def destroy_with_lock(item)
    order = item.order
    order.with_lock do
      item.destroy
      order.update_distribution_charge!
    end
  end

  def respond_to_destroy(item)
    respond_to do |format|
      format.html { redirect_to spree.cart_path }
      format.json { render json: { destroyed: item.destroyed? } }
    end
  end
end
