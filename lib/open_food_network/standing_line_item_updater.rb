module OpenFoodNetwork
  module StandingLineItemUpdater

    attr_accessor :altered_orders

    def update_line_items!
      altered_orders ||= []
      attr_names.each do |attr_name|
        unaltered_line_items(attr_name).update_all(:"#{attr_name}" => send(attr_name))
        if altered_line_items(attr_name).any?
          altered_orders |= altered_line_items(attr_name).map(&:order)
        end
      end
    end

    private

    def attr_names
      [:quantity]
    end

    def unaltered_line_items(attr_name)
      return line_items_from_future_and_undated_orders unless persisted?
      line_items_from_future_and_undated_orders.where("#{attr_name} = (?)", send("#{attr_name}_was"))
    end

    def altered_line_items(attr_name)
      line_items_from_future_and_undated_orders - unaltered_line_items(attr_name)
    end

    def line_items_from_future_and_undated_orders
      Spree::LineItem.where(order_id: standing_order.future_and_undated_orders, variant_id: variant_id)
    end
  end
end
