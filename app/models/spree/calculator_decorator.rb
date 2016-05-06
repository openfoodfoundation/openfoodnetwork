module Spree
  Calculator.class_eval do


    private

    # Given an object which might be an Order or a LineItem (amongst
    # others), return a collection of line items.
    def line_items_for(object)
      if object.respond_to? :line_items
        object.line_items
      else
        [object]
      end
    end

  end
end
