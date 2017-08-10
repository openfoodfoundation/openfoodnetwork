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
      authorize_update!

      # `with_lock` acquires an exclusive row lock on order so no other
      # requests can update it until the transaction is commited.
      # See https://github.com/rails/rails/blob/3-2-stable/activerecord/lib/active_record/locking/pessimistic.rb#L69
      # and https://www.postgresql.org/docs/current/static/sql-select.html#SQL-FOR-UPDATE-SHARE
      order.with_lock do
        if @line_item.update_attributes(params[:line_item])
          order.update_distribution_charge!
          render nothing: true, status: 204 # No Content, does not trigger ng resource auto-update
        else
          render json: { errors: @line_item.errors }, status: 412
        end
      end
    end

    # DELETE /admin/bulk_line_items/:id.json
    #
    def destroy
      load_line_item
      authorize! :update, order

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

    def authorize_update!
      authorize! :update, order
      authorize! :read, order
    end

    def order
      @line_item.order
    end
  end
end
