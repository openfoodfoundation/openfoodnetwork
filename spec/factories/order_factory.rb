# frozen_string_literal: true

FactoryBot.define do
  factory :order, class: Spree::Order do
    transient do
      shipping_method { create(:shipping_method, distributors: [distributor]) }
    end

    user
    bill_address
    completed_at { nil }
    email { user&.email || customer.email }

    factory :order_ready_for_details do
      distributor { create(:distributor_enterprise, with_payment_and_shipping: true) }
      order_cycle { create(:order_cycle, distributors: [distributor]) }

      after(:create) do |order|
        order.line_items << build(:line_item, order: order)
        order.updater.update_totals_and_states

        order.order_cycle.exchanges.outgoing.first.variants << order.line_items.first.variant
      end

      factory :order_ready_for_payment do
        bill_address
        ship_address

        after(:create) do |order, evaluator|
          order.select_shipping_method evaluator.shipping_method.id
          OrderWorkflow.new(order).advance_to_payment
        end

        factory :order_ready_for_confirmation do
          transient do
            payment_method { create(:payment_method, distributors: [distributor]) }
          end

          after(:create) do |order, evaluator|
            order.payments << build(:payment, amount: order.total, payment_method: evaluator.payment_method)
            order.next!
          end
        end
      end
    end

    factory :order_with_totals do
      after(:create) do |order|
        create(:line_item, order: order)
        order.line_items.reload # to ensure order.line_items is accessible after
        order.updater.update_totals_and_states
      end
    end

    factory :order_with_line_items do
      bill_address
      ship_address

      transient do
        line_items_count { 5 }
      end

      after(:create) do |order, evaluator|
        create(:shipment, order: order)
        order.shipments.reload

        create_list(:line_item, evaluator.line_items_count, order: order)
        order.line_items.reload
        order.update_order!
      end

      factory :completed_order_with_totals do
        state { 'complete' }
        completed_at { Time.zone.now }

        distributor { create(:distributor_enterprise) }

        after(:create, &:refresh_shipment_rates)

        factory :order_ready_to_ship do
          payment_state { 'paid' }
          shipment_state { 'ready' }
          after(:create) do |order|
            create(:payment, :completed, amount: order.total, order: order)

            order.shipments.each do |shipment|
              shipment.inventory_units.each { |u| u.update_column('state', 'on_hand') }
              shipment.update_column('state', 'ready')
            end
            order.reload
          end
        end

        factory :shipped_order do
          after(:create) do |order|
            order.shipments.each do |shipment|
              shipment.inventory_units.each { |u| u.update_column('state', 'shipped') }
              shipment.update_column('state', 'shipped')
            end
            order.reload
          end
        end
      end
    end

    trait :with_line_item do
      transient do
        variant { FactoryBot.create(:variant) }
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
        order.recreate_all_fees!
        order.ship_address = evaluator.ship_address
        break unless a = order.next! while !order.delivery?
        order.select_shipping_method(evaluator.shipping_method.id)

        break unless a = order.next! while !order.completed?
      end
    end
  end

  factory :order_with_totals_and_distribution, parent: :order_with_distributor do
    transient do
      shipping_fee { 3 }
    end

    order_cycle { create(:simple_order_cycle) }

    after(:create) do |order, proxy|
      product = create(:simple_product)
      create(:line_item_with_shipment, shipping_fee: proxy.shipping_fee,
                                       order: order,
                                       product: product)
      order.reload
    end

    trait :completed do
      transient do
        completed_at { Time.zone.now }
        state { "complete" }
        payment_method { create(:payment_method, distributors: [distributor]) }
        ship_address { create(:address) }
      end

      after(:create) do |order, evaluator|
        # Ensure order is valid and passes through necessary checkout steps
        create(:payment, state: "checkout", order: order, amount: order.total,
                         payment_method: evaluator.payment_method)
        order.ship_address = evaluator.ship_address
        break unless order.next! while !order.completed?

        order.update_columns(
          completed_at: evaluator.completed_at,
          state: evaluator.state
        )
      end
    end
  end

  factory :order_with_distributor, parent: :order do
    distributor { create(:distributor_enterprise) }
  end

  factory :order_with_taxes, parent: :completed_order_with_totals do
    transient do
      product_price { 0 }
      tax_rate_amount { 0 }
      tax_rate_name { "" }
      zone { create(:zone_with_member) }
    end

    distributor { create(:distributor_enterprise) }
    order_cycle { create(:simple_order_cycle) }

    after(:create) do |order, proxy|
      order.distributor.update_attribute(:charges_sales_tax, true)
      product = FactoryBot.create(:taxed_product, zone: proxy.zone,
                                                  price: proxy.product_price,
                                                  tax_rate_amount: proxy.tax_rate_amount,
                                                  tax_rate_name: proxy.tax_rate_name)
      FactoryBot.create(:line_item, order: order, product: product, price: product.price)
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
      create(:payment, :completed, amount: order.total + evaluator.credit_amount, order: order)

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
      create(:payment, amount: order.total - evaluator.unpaid_amount, order: order,
                       state: "completed")
      order.reload
    end
  end

  factory :completed_order_with_fees, parent: :order_with_distributor do
    transient do
      payment_fee { 5 }
      shipping_fee { 3 }
      shipping_tax_category { nil }
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
                                                   distributors: [order.distributor],
                                                   tax_category: evaluator.shipping_tax_category)

      order.reload
      break unless order.next! while !order.completed?
      order.reload
    end
  end
end
