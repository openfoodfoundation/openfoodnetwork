# frozen_string_literal: true

FactoryBot.define do
  factory :subscription, class: Subscription do
    shop { create :enterprise }
    schedule { create(:schedule, order_cycles: [create(:simple_order_cycle, coordinator: shop)]) }
    customer { create(:customer, enterprise: shop) }
    bill_address { create(:address, :randomized) }
    ship_address { create(:address, :randomized) }
    payment_method { create(:payment_method, distributors: [shop]) }
    shipping_method { create(:shipping_method, distributors: [shop]) }
    begins_at { 1.month.ago }

    transient do
      with_items { false }
      with_proxy_orders { false }
    end

    after(:create) do |subscription, proxy|
      if proxy.with_items
        subscription.subscription_line_items = build_list(:subscription_line_item,
                                                          3,
                                                          subscription: subscription)
        subscription.order_cycles.each do |oc|
          ex = oc.exchanges.outgoing.find_by(sender_id: subscription.shop_id,
                                             receiver_id: subscription.shop_id)
          ex ||= create(:exchange, order_cycle: oc,
                                   sender: subscription.shop,
                                   receiver: subscription.shop,
                                   incoming: false,
                                   pickup_time: 'time',
                                   pickup_instructions: 'instructions')
          subscription.subscription_line_items.each { |sli| ex.variants << sli.variant }
        end
      end

      if proxy.with_proxy_orders
        subscription.order_cycles.each do |oc|
          subscription.proxy_orders << create(:proxy_order, subscription: subscription,
                                                            order_cycle: oc)
        end
      end
    end
  end

  factory :subscription_line_item, class: SubscriptionLineItem do
    subscription
    variant
    quantity { 1 }
  end
end
