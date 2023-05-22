# frozen_string_literal: true

FactoryBot.define do
  factory :order_cycle, parent: :simple_order_cycle do
    coordinator_fees { [create(:enterprise_fee, enterprise: coordinator)] }

    transient do
      suppliers {
        [create(:supplier_enterprise), create(:supplier_enterprise)]
      }
      distributors {
        [create(:distributor_enterprise), create(:distributor_enterprise)]
      }
    end

    after(:create) do |_oc, proxy|
      proxy.exchanges.incoming.each do |exchange|
        ExchangeFee.create!(
          exchange: exchange,
          enterprise_fee: create(:enterprise_fee, enterprise: exchange.sender)
        )
      end

      proxy.exchanges.outgoing.each do |exchange|
        ExchangeFee.create!(
          exchange: exchange,
          enterprise_fee: create(:enterprise_fee, enterprise: exchange.receiver)
        )
      end

      # Products with images
      proxy.exchanges.incoming.each do |exchange|
        product = create(:product, supplier: exchange.sender)
        Spree::Image.create(
          viewable_id: product.id,
          viewable_type: 'Spree::Product',
          alt: "position 1",
          attachment: Rack::Test::UploadedFile.new(white_logo_path),
          position: 1
        )

        exchange.variants << product.variants.first
      end

      variants = proxy.exchanges.incoming.map(&:variants).flatten
      proxy.exchanges.outgoing.each do |exchange|
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

  # Note: Order cycles are sometimes referred to as 'simple if they are for a shop selling their
  # own produce i.e. :sells = 'own'. However the 'simple_order_cycle' name does not mean this
  # and may need to be renamed to avoid potential confusion because it actually can create
  # 'non-simple' order cycles too for distributors selling produce from other enterprises.
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
      # Incoming Exchanges
      proxy.suppliers.each.with_index do |supplier, i|
        ex = create(:exchange, order_cycle: oc,
                               sender: supplier,
                               receiver: oc.coordinator,
                               incoming: true,
                               receival_instructions: "instructions #{i}")
        proxy.variants.each { |v| ex.variants << v }
      end

      # Outgoing Exchanges
      proxy.distributors.each.with_index do |distributor, i|
        ex = create(:exchange, order_cycle: oc,
                               sender: oc.coordinator,
                               receiver: distributor,
                               incoming: false,
                               pickup_time: "time #{i}",
                               pickup_instructions: "instructions #{i}")
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

  factory :distributor_order_cycle, parent: :simple_order_cycle do
    coordinator { create(:distributor_enterprise) }
  end

  factory :sells_own_order_cycle, parent: :simple_order_cycle do
    coordinator { create(:enterprise, sells: "own") }
  end
end
