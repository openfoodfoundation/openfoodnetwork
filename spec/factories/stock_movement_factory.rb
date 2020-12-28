# frozen_string_literal: true

FactoryBot.define do
  factory :stock_movement, class: Spree::StockMovement do
    quantity { 1 }
    action { 'sold' }
  end
end
