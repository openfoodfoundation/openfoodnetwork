module Admin
  class BulkLineItemsController < Spree::Admin::BaseController
    # GET /admin/bulk_line_items.json
    #
    def index
      order_params = params[:q].andand.delete :order
      orders = order_permissions.editable_orders.ransack(order_params).result

      @line_items = order_permissions.
        editable_line_items.where(order_id: orders).
        includes(variant: { option_values: :option_type }).
        ransack(params[:q]).result.
        reorder('spree_line_items.order_id ASC, spree_line_items.id ASC')

      @line_items = @line_items.page(page).per(params[:per_page]) if using_pagination?

      render json: { line_items: serialized_line_items, pagination: pagination_data }
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
        if @line_item.update(line_item_params)
          order.update_distribution_charge!
          render nothing: true, status: :no_content # No Content, does not trigger ng resource auto-update
        else
          render json: { errors: @line_item.errors }, status: :precondition_failed
        end
      end
    end

    # DELETE /admin/bulk_line_items/:id.json
    #
    def destroy
      load_line_item
      authorize! :update, order

      @line_item.destroy
      render nothing: true, status: :no_content # No Content, does not trigger ng resource auto-update
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

    def serialized_line_items
      ActiveModel::ArraySerializer.new(
        @line_items, each_serializer: serializer(nil)
      )
    end

    def authorize_update!
      authorize! :update, order
      authorize! :read, order
    end

    def order
      @line_item.order
    end

    def line_item_params
      params.require(:line_item).permit(:price, :quantity, :final_weight_volume)
    end

    def order_permissions
      ::Permissions::Order.new(spree_current_user)
    end

    def using_pagination?
      params[:per_page]
    end

    def pagination_data
      return unless using_pagination?

      {
        results: @line_items.total_count,
        pages: @line_items.num_pages,
        page: page.to_i,
        per_page: params[:per_page].to_i
      }
    end

    def page
      params[:page] || 1
    end
  end
end
