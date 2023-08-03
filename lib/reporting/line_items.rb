# frozen_string_literal: true

module Reporting
  # shared code to search and list line items
  class LineItems
    def initialize(order_permissions, params, orders_relation = nil)
      @order_permissions = order_permissions
      @params = params
      complete_not_canceled_visible_orders =
        CompleteVisibleOrders.new(order_permissions).query.not_state(:canceled)
      @orders_relation = orders_relation || complete_not_canceled_visible_orders
    end

    def orders
      @orders ||= search_orders
    end

    def list(line_item_includes = [variant: [product: :supplier]])
      line_items = order_permissions.visible_line_items.in_orders(orders.result)
        .order("supplier.name", "product.name", "variant.display_name")

      if @params[:supplier_id_in].present?
        line_items = line_items.supplied_by_any(@params[:supplier_id_in])
      end

      # Filter by product
      variant_id_in = @params[:variant_id_in]&.compact_blank
      if variant_id_in.present?
        line_items = line_items.where('spree_line_items.variant_id': variant_id_in)
      end

      if line_item_includes.present?
        line_items = line_items.includes(*line_item_includes).references(:line_items)
      end

      without_editable_line_items = line_items - editable_line_items(line_items)

      without_editable_line_items.each do |line_item|
        OrderDataMasker.new(line_item.order).call
      end

      line_items
    end

    private

    attr_reader :orders_relation, :order_permissions

    def search_orders
      orders_relation.ransack(@params[:q])
    end

    # From the line_items given, returns the ones that are editable by the user
    def editable_line_items(line_items)
      editable_line_items_ids = order_permissions.editable_line_items.select(:id)

      # Although merge could take a relation, here we convert line_items to array
      #   because, if we pass a relation, merge will overwrite the conditions on the same field
      #   In this case: the IN clause on spree_line_items.order_id from line_items
      #     overwrites the IN clause on spree_line_items.order_id on editable_line_items_ids
      # We convert to array the relation with less elements: line_items
      editable_line_items_ids.merge(line_items.to_a)
    end
  end
end
