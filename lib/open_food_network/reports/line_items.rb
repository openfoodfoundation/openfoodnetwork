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

        # If empty array is passed in, the where clause will return all line_items, which is bad
        line_items_with_hidden_details =
          permissions.editable_line_items.empty? ? line_items : line_items.where('"spree_line_items"."id" NOT IN (?)', permissions.editable_line_items)

        line_items.select{ |li| line_items_with_hidden_details.include? li }.each do |line_item|
          # TODO We should really be hiding customer code here too, but until we
          # have an actual association between order and customer, it's a bit tricky
          line_item.order.bill_address.andand.assign_attributes(firstname: I18n.t('admin.reports.hidden'), lastname: "", phone: "", address1: "", address2: "", city: "", zipcode: "", state: nil)
          line_item.order.ship_address.andand.assign_attributes(firstname: I18n.t('admin.reports.hidden'), lastname: "", phone: "", address1: "", address2: "", city: "", zipcode: "", state: nil)
          line_item.order.assign_attributes(email: I18n.t('admin.reports.hidden'))
        end
        line_items
      end
    end
  end
end
