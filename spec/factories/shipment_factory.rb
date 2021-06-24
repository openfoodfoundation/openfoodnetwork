# frozen_string_literal: true

FactoryBot.define do
  factory :shipment, class: Spree::Shipment do
    # keeps test shipments unique per order
    initialize_with { Spree::Shipment.find_or_create_by(order_id: order.id) }

    tracking { 'U10000' }
    number { '100' }
    cost { 100.00 }
    state { 'pending' }
    order
    address
    stock_location { Spree::StockLocation.first || create(:stock_location) }

    after(:create) do |shipment, _evalulator|
      shipment.add_shipping_method(create(:shipping_method), true)

      shipment.order.line_items.each do |line_item|
        line_item.quantity.times {
          shipment.inventory_units.create(variant_id: line_item.variant_id)
        }
      end
    end
  end

  factory :shipment_with, class: Spree::Shipment do
    tracking { 'U10000' }
    number { '100' }
    cost { 100.00 }
    state { 'pending' }
    order
    address
    stock_location { Spree::StockLocation.first || create(:stock_location) }

    trait :shipping_method do
      transient do
        shipping_method { create(:shipping_method) }
      end

      shipping_rates {
        [Spree::ShippingRate.create(shipping_method: shipping_method, selected: true)]
      }

      after(:create) do |shipment, _evaluator|
        shipment.order.line_items.each do |line_item|
          line_item.quantity.times {
            shipment.inventory_units.create(variant_id: line_item.variant_id)
          }
        end

        # Ensure correct shipping cost is assigned to both shipping rate and shipment.
        # This usually happens via Stock::Estimator when shipping rates are created.
        computed_shipping_cost = shipment.shipping_method.calculator.compute(shipment.to_package)
        shipment.selected_shipping_rate.update_columns(cost: computed_shipping_cost)
        shipment.update_columns(cost: computed_shipping_cost)
      end
    end
  end
end
