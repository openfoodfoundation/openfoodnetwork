FactoryBot.modify do
  factory :order do
    trait :with_line_item do
      transient do
        variant { FactoryGirl.create(:variant) }
      end

      after(:create) do |order, evaluator|
        create(:line_item, order: order, variant: evaluator.variant)
      end
    end

    trait :completed do
      transient do
        payment_method { create(:payment_method, distributors: [distributor]) }
      end

      after(:create) do |order, evaluator|
        order.create_shipment!
        create(:payment, state: "checkout", order: order, amount: order.total,
                         payment_method: evaluator.payment_method)
        order.update_distribution_charge!
        while !order.completed? do break unless order.next! end
      end
    end
  end
end
