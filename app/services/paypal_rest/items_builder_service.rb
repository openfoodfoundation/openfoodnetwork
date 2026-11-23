# frozen_string_literal: true

module PaypalRest
  class ItemsBuilderService
    def initialize(order)
      @order = order
    end

    def call
      items = order.line_items.map(&method(:line_item_data))

      positive_adjustments.each do |adjustment|
        items << adjustment_data(adjustment)
      end

      items.reject { |item| item[:unit_amount][:value].to_d.zero? }
    end

    def discount_total
      negative_adjustments_total = relevant_adjustments.
        select { |adjustment| adjustment.amount.negative? }.
        sum(&:amount)

      (-negative_adjustments_total + customer_credit).to_d
    end

    private

    attr_reader :order

    def relevant_adjustments
      @relevant_adjustments ||= order.all_adjustments.eligible -
                                order.all_adjustments.tax.to_a -
                                order.all_adjustments.shipping.to_a
    end

    def positive_adjustments
      relevant_adjustments.select { |adjustment| adjustment.amount.positive? }
    end

    def customer_credit
      (Orders::FindPaymentService.new(order).last_customer_credit&.amount || 0).to_d
    end

    def line_item_data(item)
      {
        name: item.product.name.to_s.truncate(127),
        sku: item.variant.sku,
        quantity: item.quantity.to_s,
        unit_amount: money(item.price),
        category: PaypalServerSdk::ItemCategory::PHYSICAL_GOODS
      }.compact
    end

    def adjustment_data(adjustment)
      {
        name: adjustment.label.to_s.truncate(127),
        quantity: "1",
        unit_amount: money(adjustment.amount)
      }
    end

    def money(value)
      {
        currency_code: order.currency,
        value: format("%.2f", value)
      }
    end
  end
end
