# frozen_string_literal: true

FactoryBot.define do
  factory :order_cycle, parent: :simple_order_cycle do
    coordinator_fees { [create(:enterprise_fee, enterprise: coordinator)] }

    after(:create) do |oc|
      # Suppliers
      supplier1 = create(:supplier_enterprise)
      supplier2 = create(:supplier_enterprise)

      # Incoming Exchanges
      ex1 = create(:exchange, order_cycle: oc, incoming: true,
                              sender: supplier1, receiver: oc.coordinator,
                              receival_instructions: 'instructions 0')
      ex2 = create(:exchange, order_cycle: oc, incoming: true,
                              sender: supplier2, receiver: oc.coordinator,
                              receival_instructions: 'instructions 1')
      ExchangeFee.create!(exchange: ex1,
                          enterprise_fee: create(:enterprise_fee, enterprise: ex1.sender))
      ExchangeFee.create!(exchange: ex2,
                          enterprise_fee: create(:enterprise_fee, enterprise: ex2.sender))

      # Distributors
      distributor1 = create(:distributor_enterprise)
      distributor2 = create(:distributor_enterprise)

      # Outgoing Exchanges
      ex3 = create(:exchange, order_cycle: oc, incoming: false,
                              sender: oc.coordinator, receiver: distributor1,
                              pickup_time: 'time 0', pickup_instructions: 'instructions 0')
      ex4 = create(:exchange, order_cycle: oc, incoming: false,
                              sender: oc.coordinator, receiver: distributor2,
                              pickup_time: 'time 1', pickup_instructions: 'instructions 1')
      ExchangeFee.create!(exchange: ex3,
                          enterprise_fee: create(:enterprise_fee, enterprise: ex3.receiver))
      ExchangeFee.create!(exchange: ex4,
                          enterprise_fee: create(:enterprise_fee, enterprise: ex4.receiver))

      # Products with images
      [ex1, ex2].each do |exchange|
        product = create(:product, supplier: exchange.sender)
        image = File.open(File.expand_path('../../app/assets/images/logo-white.png', __dir__))
        Spree::Image.create(
          viewable_id: product.master.id,
          viewable_type: 'Spree::Variant',
          alt: "position 1",
          attachment: image,
          position: 1
        )

        exchange.variants << product.variants.first
      end

      variants = [ex1, ex2].map(&:variants).flatten
      [ex3, ex4].each do |exchange|
        variants.each { |v| exchange.variants << v }
      end
    end
  end

  factory :order_cycle_with_overrides, parent: :order_cycle do
    after(:create) do |oc|
      oc.variants.each do |variant|
        create(:variant_override, variant: variant,
                                  hub: oc.distributors.first,
                                  price: variant.price + 100)
      end
    end
  end

  factory :simple_order_cycle, class: OrderCycle do
    sequence(:name) { |n| "Order Cycle #{n}" }

    orders_open_at  { 1.day.ago }
    orders_close_at { 1.week.from_now }

    coordinator { Enterprise.is_distributor.first || FactoryBot.create(:distributor_enterprise) }

    transient do
      suppliers { [] }
      distributors { [] }
      variants { [] }
    end

    after(:create) do |oc, proxy|
      proxy.suppliers.each do |supplier|
        ex = create(:exchange, order_cycle: oc,
                               sender: supplier,
                               receiver: oc.coordinator,
                               incoming: true,
                               receival_instructions: 'instructions')
        proxy.variants.each { |v| ex.variants << v }
      end

      proxy.distributors.each do |distributor|
        ex = create(:exchange, order_cycle: oc,
                               sender: oc.coordinator,
                               receiver: distributor,
                               incoming: false,
                               pickup_time: 'time',
                               pickup_instructions: 'instructions')
        proxy.variants.each { |v| ex.variants << v }
      end
    end
  end

  factory :undated_order_cycle, parent: :simple_order_cycle do
    orders_open_at { nil }
    orders_close_at { nil }
  end

  factory :upcoming_order_cycle, parent: :simple_order_cycle do
    orders_open_at  { 1.week.from_now }
    orders_close_at { 2.weeks.from_now }
  end

  factory :open_order_cycle, parent: :simple_order_cycle do
    orders_open_at  { 1.week.ago }
    orders_close_at { 1.week.from_now }
  end

  factory :closed_order_cycle, parent: :simple_order_cycle do
    orders_open_at  { 2.weeks.ago }
    orders_close_at { 1.week.ago }
  end
end
