FactoryBot.modify do
  factory :variant do
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
