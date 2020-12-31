# frozen_string_literal: true

FactoryBot.define do
  factory :stock_package, class: OrderManagement::Stock::Package do
    transient do
      stock_location { build(:stock_location) }
      order { create(:order_with_line_items, line_items_count: 2) }
      contents { [] }
    end

    initialize_with { new(stock_location, order, contents) }

    factory :stock_package_fulfilled do
      after(:build) do |package, evaluator|
        evaluator.order.line_items.reload
        evaluator.order.line_items.each do |line_item|
          package.add line_item.variant, line_item.quantity, :on_hand
        end
      end
    end
  end
end
