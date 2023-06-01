# frozen_string_literal: true

FactoryBot.define do
  sequence(:random_float) { BigDecimal("#{rand(200)}.#{rand(99)}") }

  factory :base_variant, class: Spree::Variant do
    price { 19.99 }
    sku    { SecureRandom.hex }
    weight { generate(:random_float) }
    height { generate(:random_float) }
    width  { generate(:random_float) }
    depth  { generate(:random_float) }

    product { |p| p.association(:base_product) }

    # ensure stock item will be created for this variant
    before(:create) { create(:stock_location) if Spree::StockLocation.count.zero? }

    factory :variant do
      transient do
        on_demand { false }
        on_hand { 5 }
      end

      product { |p| p.association(:product) }
      unit_value { 1 }
      unit_description { '' }

      after(:create) do |variant, evaluator|
        variant.on_demand = evaluator.on_demand
        variant.on_hand = evaluator.on_hand
        variant.save
      end

      trait :with_order_cycle do
        transient do
          order_cycle { create(:order_cycle) }
          producer { product.supplier }
          coordinator { create(:distributor_enterprise) }
          distributor { create(:distributor_enterprise) }
          incoming_exchange_fees { [] }
          outgoing_exchange_fees { [] }
        end

        after(:create) do |variant, evaluator|
          exchange_attributes = { order_cycle_id: evaluator.order_cycle.id, incoming: true,
                                  sender_id: evaluator.producer.id,
                                  receiver_id: evaluator.coordinator.id }
          exchange = Exchange.where(exchange_attributes).first_or_create!(exchange_attributes)
          exchange.variants << variant
          evaluator.incoming_exchange_fees.each do |enterprise_fee|
            exchange.enterprise_fees << enterprise_fee
          end

          exchange_attributes = { order_cycle_id: evaluator.order_cycle.id, incoming: false,
                                  sender_id: evaluator.coordinator.id,
                                  receiver_id: evaluator.distributor.id }
          exchange = Exchange.where(exchange_attributes).first_or_create!(exchange_attributes)
          exchange.variants << variant
          (evaluator.outgoing_exchange_fees || []).each do |enterprise_fee|
            exchange.enterprise_fees << enterprise_fee
          end
        end
      end
    end
  end
end
