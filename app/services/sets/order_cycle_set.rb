# frozen_string_literal: true

module Sets
  class OrderCycleSet < ModelSet
    def initialize(collection, attributes = {})
      @confirm_datetime_change = attributes.delete :confirm_datetime_change
      @error_class = attributes.delete :error_class

      super(OrderCycle, collection, attributes)
    end

    def process(order_cycle, attributes)
      if @confirm_datetime_change &&
         order_cycle.orders.exists? &&
         datetime_value_changed(order_cycle, attributes)
        raise @error_class
      end

      super
    end

    private

    def datetime_value_changed(order_cycle, attributes)
      # return true if either key is present in params and change in values detected
      return true if attributes.key?(:orders_open_at) &&
                     !order_cycle.same_datetime_value(:orders_open_at, attributes[:orders_open_at])

      attributes.key?(:orders_close_at) &&
        !order_cycle.same_datetime_value(:orders_close_at, attributes[:orders_close_at])
    end
  end
end
