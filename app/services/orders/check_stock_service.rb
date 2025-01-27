# frozen_string_literal: true

module Orders
  class CheckStockService
    attr_reader :order

    def initialize(order: )
      @order = order
    end

    def sufficient_stock?
      @sufficient_stock ||= order.insufficient_stock_lines.blank?
    end
  end
end
