FactoryBot.define do
  factory :order_with_totals_and_distribution, parent: :order_with_distributor do
    transient do
      shipping_fee 3
    end

    order_cycle { create(:simple_order_cycle) }

    after(:create) do |order, proxy|
      product = create(:simple_product)
      create(:line_item_with_shipment, shipping_fee: proxy.shipping_fee,
                                       order: order,
                                       product: product)
      order.reload
    end
  end

  factory :order_with_distributor, parent: :order do
    distributor { create(:distributor_enterprise) }
  end

  factory :order_with_taxes, parent: :completed_order_with_totals do
    transient do
      product_price 0
      tax_rate_amount 0
      tax_rate_name ""
    end

    distributor { create(:distributor_enterprise) }
    order_cycle { create(:simple_order_cycle) }

    after(:create) do |order, proxy|
      order.distributor.update_attribute(:charges_sales_tax, true)
      Spree::Zone.global.update_attribute(:default_tax, true)

      p = FactoryBot.create(:taxed_product, zone: Spree::Zone.global,
                                            price: proxy.product_price,
                                            tax_rate_amount: proxy.tax_rate_amount,
                                            tax_rate_name: proxy.tax_rate_name)
      FactoryBot.create(:line_item, order: order, product: p, price: p.price)
      order.reload
    end
  end

  factory :order_with_credit_payment, parent: :completed_order_with_totals do
    distributor { create(:distributor_enterprise) }
    order_cycle { create(:simple_order_cycle) }

    transient do
      credit_amount { 10_000 }
    end

    after(:create) do |order, evaluator|
      create(:payment, amount: order.total + evaluator.credit_amount, order: order, state: "completed")
      order.reload
    end
  end

  factory :order_without_full_payment, parent: :completed_order_with_totals do
    distributor { create(:distributor_enterprise) }
    order_cycle { create(:simple_order_cycle) }

    transient do
      unpaid_amount { 1 }
    end

    after(:create) do |order, evaluator|
      create(:payment, amount: order.total - evaluator.unpaid_amount, order: order, state: "completed")
      order.reload
    end
  end

  factory :completed_order_with_fees, parent: :order_with_distributor do
    transient do
      payment_fee 5
      shipping_fee 3
    end

    ship_address { create(:address) }
    order_cycle { create(:simple_order_cycle) }

    after(:create) do |order, evaluator|
      create(:line_item, order: order)
      product = create(:simple_product)
      create(:line_item, order: order, product: product)

      payment_calculator = build(:calculator_per_item, preferred_amount: evaluator.payment_fee)
      payment_method = create(:payment_method, calculator: payment_calculator)
      create(:payment, order: order,
                       amount: order.total,
                       payment_method: payment_method,
                       state: 'checkout')

      create(:shipping_method_with, :shipping_fee, shipping_fee: evaluator.shipping_fee,
                                                   distributors: [order.distributor])

      order.reload
      while !order.completed? do break unless order.next! end
    end
  end
end

FactoryBot.modify do
  factory :order do
    transient do
      shipping_method { create(:shipping_method, distributors: [distributor]) }
    end

    trait :with_line_item do
      transient do
        variant { FactoryGirl.create(:variant) }
      end

      after(:create) do |order, evaluator|
        line_item = create(:line_item_with_shipment, order: order,
                                                     variant: evaluator.variant,
                                                     shipping_method: evaluator.shipping_method)
        order.shipments << line_item.target_shipment
      end
    end

    trait :completed do
      transient do
        payment_method { create(:payment_method, distributors: [distributor]) }
        ship_address { create(:address) }
      end

      after(:create) do |order, evaluator|
        create(:payment, state: "checkout", order: order, amount: order.total,
                         payment_method: evaluator.payment_method)
        order.update_distribution_charge!
        order.ship_address = evaluator.ship_address
        while !order.completed? do break unless a = order.next! end
        order.select_shipping_method(evaluator.shipping_method.id)
      end
    end
  end

  factory :completed_order_with_totals do
    distributor { create(:distributor_enterprise) }
  end
end
