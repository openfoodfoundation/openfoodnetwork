module OpenFoodNetwork
  module Reports
    # shared code to search and list line items
    module LineItems
      def self.search_orders(permissions, params)
        permissions.visible_orders.complete.not_state(:canceled).search(params[:q])
      end

      def self.list(permissions, params)
        orders = search_orders(permissions, params).result

        line_items = permissions.visible_line_items.merge(Spree::LineItem.where(order_id: orders))
        line_items = line_items.supplied_by_any(params[:supplier_id_in]) if params[:supplier_id_in].present?

        if params[:line_item_includes].present?
          line_items = line_items.includes(*params[:line_item_includes])
        end

        hidden_line_items = line_items_with_hidden_details(permissions, line_items)

        line_items.select{ |li|
          hidden_line_items.include? li
        }.each do |line_item|
          # TODO We should really be hiding customer code here too, but until we
          # have an actual association between order and customer, it's a bit tricky
          line_item.order.bill_address.andand.assign_attributes(firstname: I18n.t('admin.reports.hidden'), lastname: "", phone: "", address1: "", address2: "", city: "", zipcode: "", state: nil)
          line_item.order.ship_address.andand.assign_attributes(firstname: I18n.t('admin.reports.hidden'), lastname: "", phone: "", address1: "", address2: "", city: "", zipcode: "", state: nil)
          line_item.order.assign_attributes(email: I18n.t('admin.reports.hidden'))
        end
        line_items
      end

      def self.line_items_with_hidden_details(permissions, line_items)
        editable_line_items = permissions.editable_line_items.pluck(:id)

        if editable_line_items.empty?
          line_items
        else
          line_items.where('"spree_line_items"."id" NOT IN (?)', editable_line_items)
        end
      end
    end
  end
end
