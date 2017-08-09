module Admin
  class BulkLineItemsController < Spree::Admin::BaseController

    # GET /admin/bulk_line_items.json
    #
    def index
      order_params = params[:q].andand.delete :order
      orders = OpenFoodNetwork::Permissions.new(spree_current_user).editable_orders.ransack(order_params).result
      line_items = OpenFoodNetwork::Permissions.new(spree_current_user).editable_line_items.where(order_id: orders).ransack(params[:q])
      render_as_json line_items.result.reorder('order_id ASC, id ASC')
    end

    # PUT /admin/bulk_line_items/:id.json
    #
    def update
      load_line_item
      authorize! :update, @line_item.order

      if @line_item.update_attributes(params[:line_item])
        render nothing: true, status: 204 # No Content, does not trigger ng resource auto-update
      else
        render json: { errors: @line_item.errors }, status: 412
      end
    end

    # DELETE /admin/bulk_line_items/:id.json
    #
    def destroy
      load_line_item
      authorize! :update, @line_item.order

      @line_item.destroy
      render nothing: true, status: 204 # No Content, does not trigger ng resource auto-update
    end

    private

    def load_line_item
      @line_item = Spree::LineItem.find(params[:id])
    end

    def model_class
      Spree::LineItem
    end

    # Returns the appropriate serializer for this controller
    #
    # @return [Api::Admin::LineItemSerializer]
    def serializer(_ams_prefix)
      Api::Admin::LineItemSerializer
    end
  end
end
