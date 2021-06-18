# frozen_string_literal: true

FactoryBot.define do
  factory :line_item, class: Spree::LineItem do
    quantity { 1 }
    price { BigDecimal('10.00') }
    order
    variant
  end

  factory :line_item_with_shipment, parent: :line_item do
    transient do
      shipping_fee { 3 }
      shipping_method { nil }
    end

    after(:build) do |line_item, evaluator|
      shipment = line_item.order.reload.shipments.first
      if shipment.nil?
        shipping_method = evaluator.shipping_method
        unless shipping_method
          shipping_method = create(:shipping_method_with, :shipping_fee,
                                   shipping_fee: evaluator.shipping_fee)
          shipping_method.distributors << line_item.order.distributor if line_item.order.distributor
        end
        shipment = create(:shipment_with, :shipping_method, shipping_method: shipping_method,
                                                            order: line_item.order)
      end
      line_item.target_shipment = shipment
    end
  end
end
