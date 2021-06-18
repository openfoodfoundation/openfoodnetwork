# frozen_string_literal: true

class LineItemsController < BaseController
  respond_to :json

  before_action :load_line_item, only: :destroy

  def bought
    respond_with bought_items, each_serializer: Api::LineItemSerializer
  end

  def destroy
    authorize! :destroy, @line_item
    destroy_with_lock @line_item
    respond_with(@line_item)
  end

  private

  def load_line_item
    @line_item = Spree::LineItem.find_by(id: params[:id])
    not_found unless @line_item
  end

  # List all items the user already ordered in the current order cycle
  def bought_items
    return [] unless current_order_cycle && spree_current_user && current_distributor

    current_order_cycle.items_bought_by_user(spree_current_user, current_distributor)
  end

  def unauthorized
    status = spree_current_user ? 403 : 401
    render(body: nil, status: status) && return
  end

  def not_found
    render(body: nil, status: :not_found) && return
  end

  def destroy_with_lock(item)
    order = item.order
    order.with_lock do
      order.contents.remove(item.variant)
      order.update_payment_fees!
    end
  end
end
