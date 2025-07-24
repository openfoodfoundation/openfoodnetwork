# frozen_string_literal: true

module Admin
  class BulkLineItemsController < Spree::Admin::BaseController
    include PaginationData
    # GET /admin/bulk_line_items.json
    #
    def index
      order_params = params[:q]&.delete :order
      orders = order_permissions.editable_orders.ransack(order_params).result

      @line_items = order_permissions.
        editable_line_items.where(order_id: orders).
        includes(:variant).
        ransack(line_items_search_query).result.order(:id)

      @pagy, @line_items = pagy(@line_items) if pagination_required?

      render json: {
        line_items: serialized_line_items,
        pagination: pagination_data
      }
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
        if order.contents.update_item(@line_item, line_item_params)
          # No Content, does not trigger ng resource auto-update
          head :no_content
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

      order.contents.remove(@line_item.variant)
      head :no_content # No Content, does not trigger ng resource auto-update
    end

    private

    def load_line_item
      @line_item = Spree::LineItem.find(params[:id])
    end

    def model_class
      Spree::LineItem
    end

    def serialized_line_items
      ActiveModel::ArraySerializer.new(
        @line_items, each_serializer: Api::Admin::LineItemSerializer
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

    def page
      params[:page] || 1
    end

    def line_items_search_query
      query = params.permit(q: {}).to_h[:q] || {}

      search_fields_string = [
        spree_current_user.admin? ? "order_distributor_name" : "order_distributor_name_alias",
        "order_bill_address_phone",
        "order_bill_address_firstname",
        "order_bill_address_lastname",
        "order_bill_address_full_name",
        "order_bill_address_full_name_reversed",
        "order_bill_address_full_name_with_comma",
        "order_bill_address_full_name_with_comma_reversed",
        "variant_supplier_name",
        "order_email",
        "order_number",
        "product_name"
      ].join("_or_")
      search_query = "#{search_fields_string}_cont"

      query.merge({ search_query => params[:search_query] })
    end
  end
end
