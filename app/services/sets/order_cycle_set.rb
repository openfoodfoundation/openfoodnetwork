# frozen_string_literal: true

module Sets
  class OrderCycleSet < ModelSet
    def initialize(collection, attributes = {})
      @confirm_datetime_change = attributes.delete :confirm_datetime_change
      @error_class = attributes.delete :error_class

      super(OrderCycle, collection, attributes)
    end

    def process(found_element, attributes)
      if @confirm_datetime_change && found_element.orders.exists? &&
         ((attributes.key?(:orders_open_at) &&
           !found_element.same_datetime_value(:orders_open_at, attributes[:orders_open_at])) ||
          (attributes.key?(:orders_close_at) &&
            !found_element.same_datetime_value(:orders_close_at, attributes[:orders_close_at])))
        raise @error_class
      end

      super
    end
  end
end
