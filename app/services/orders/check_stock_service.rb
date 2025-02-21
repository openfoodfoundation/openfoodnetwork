# frozen_string_literal: true

module Orders
  class CheckStockService
    attr_reader :order

    def initialize(order:)
      @order = order
    end

    def sufficient_stock?
      return @sufficient_stock if defined? @sufficient_stock

      @sufficient_stock = order.insufficient_stock_lines.blank?
    end

    def update_line_items
      return [] if sufficient_stock?

      variants = []
      order.insufficient_stock_lines.each do |line_item|
        order.contents.update_item(line_item, { quantity: line_item.variant.on_hand })
        variants.push line_item.variant
      end

      variants
    end
  end
end
