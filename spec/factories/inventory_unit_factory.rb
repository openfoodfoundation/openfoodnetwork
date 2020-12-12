# frozen_string_literal: true

FactoryBot.define do
  factory :inventory_unit, class: Spree::InventoryUnit do
    variant
    order
    state { 'on_hand' }
    association(:shipment, factory: :shipment, state: 'pending')
  end
end
