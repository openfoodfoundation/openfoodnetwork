require 'spec_helper'

describe Spree::Admin::ReportsController, type: :controller do
  let(:csv) do
    <<-CSV.strip_heredoc
      Hub,Producer,Product,Variant,Amount,Curr. Cost per Unit,Total Cost,Total Shipping Cost,Shipping Method
      Mary's Online Shop,Freddy's Farm Shop,Beef - 5kg Trays,1g,1,12.0,12.0,"",Shipping Method
      Mary's Online Shop,Freddy's Farm Shop,Fuji Apple,2g,1,4.0,4.0,"",Shipping Method
      Mary's Online Shop,Freddy's Farm Shop,Fuji Apple,5g,5,12.0,60.0,"",Shipping Method
      Mary's Online Shop,Freddy's Farm Shop,Fuji Apple,8g,3,15.0,45.0,"",Shipping Method
      "",TOTAL,"","","","",121.0,2.0,""
    CSV
  end

  before do
    DefaultStockLocation.create!

    delivery  = marys_online_shop.shipping_methods.new(
      name: "Home delivery",
      require_ship_address: true,
      calculator_type: "Spree::Calculator::FlatRate",
      distributor_ids: [marys_online_shop.id]
    )
    delivery.shipping_categories << DefaultShippingCategory.find_or_create
    delivery.calculator.preferred_amount = 2
    delivery.save!
  end

  let(:taxonomy) { Spree::Taxonomy.create!(name: 'Products') }
  let(:meat) do
    Spree::Taxon.create!(name: 'Meat and Fish', parent_id: taxonomy.root.id, taxonomy_id: taxonomy.id)
  end
  let(:fruit) do
    Spree::Taxon.create!(name: 'Fruit', parent_id: taxonomy.root.id, taxonomy_id: taxonomy.id)
  end

  let(:calculator) { Calculator::FlatPercentPerItem.new(preferred_flat_percent: 10) }

  let(:mary) do
    password = Spree::User.friendly_token
    Spree::User.create!(
      email: 'mary_retailer@example.org',
      password: password,
      password_confirmation: password,
      confirmation_sent_at: Time.zone.now,
      confirmed_at: Time.zone.now
    )
  end
  let(:marys_online_shop) do
    Enterprise.create!(
      name: "Mary's Online Shop",
      owner: mary,
      is_primary_producer: false,
      sells: "any",
      address: create(:address)
    )
  end
  before do
    fee = marys_online_shop.enterprise_fees.new(
      fee_type: "sales", name: "markup", inherits_tax_category: true
    )
    fee.calculator = calculator
    fee.save!
  end

  let(:freddy) do
    password = Spree::User.friendly_token
    Spree::User.create!(
      email: 'freddy_shop_farmer@example.org',
      password: password,
      password_confirmation: password,
      confirmation_sent_at: Time.zone.now,
      confirmed_at: Time.zone.now
    )
  end
  let(:freddys_farm_shop) do
    Enterprise.create!(
      name: "Freddy's Farm Shop",
      owner: freddy,
      is_primary_producer: true,
      sells: "own",
      address: create(:address)
    )
  end
  before do
    fee = freddys_farm_shop.enterprise_fees.new(
      fee_type: "sales", name: "markup", inherits_tax_category: true,
    )
    fee.calculator = calculator
    fee.save!
  end

  let!(:beef) do
    product = Spree::Product.new(
      name: 'Beef - 5kg Trays',
      price: 50.00,
      supplier_id: freddys_farm_shop.id,
      primary_taxon_id: meat.id,
      variant_unit: "weight",
      variant_unit_scale: 1,
      unit_value: 1,
    )
    product.shipping_category = DefaultShippingCategory.find_or_create
    product.save!
    product.variants.first.update_attribute(:on_demand, true)

    InventoryItem.create!(
      enterprise: marys_online_shop,
      variant: product.variants.first,
      visible: true
    )
    VariantOverride.create!(
      variant: product.variants.first,
      hub: marys_online_shop,
      price: 12,
      on_demand: false,
      count_on_hand: 5
    )

    product
  end

  let!(:apple) do
    product = Spree::Product.new(
      name: 'Fuji Apple',
      price: 5.00,
      supplier_id: freddys_farm_shop.id,
      primary_taxon_id: fruit.id,
      variant_unit: "weight",
      variant_unit_scale: 1,
      unit_value: 1,
      shipping_category: DefaultShippingCategory.find_or_create
    )
    product.shipping_category = DefaultShippingCategory.find_or_create
    product.save!
    product.variants.first.update_attribute :on_demand, true

    VariantOverride.create!(
      variant: product.variants.first,
      hub: marys_online_shop,
      price: 12,
      on_demand: false,
      count_on_hand: 5
    )

    product
  end
  let!(:apple_variant_2) do
    variant = apple.variants.create!(weight: 0.0, unit_value: 2.0, price: 4.0)
    VariantOverride.create!(
      variant: variant, hub: marys_online_shop, on_demand: false, count_on_hand: 4
    )
    variant
  end
  let!(:apple_variant_5) do
    variant = apple.variants.create!(weight: 0.0, unit_value: 5.0, price: 12.0)
    VariantOverride.create!(
      variant: variant, hub: marys_online_shop, on_demand: false, count_on_hand: 5
    )
    variant.update_attribute :on_demand, true
    variant
  end
  let!(:apple_variant_8) do
    variant = apple.variants.create!(weight: 0.0, unit_value: 8.0, price: 15.0)
    VariantOverride.create!(
      variant: variant, hub: marys_online_shop, on_demand: false, count_on_hand: 3
    )
    variant.update_attribute :on_demand, true
    variant
  end

  let!(:beef_variant) do
    variant = beef.variants.first
    OpenFoodNetwork::ScopeVariantToHub.new(marys_online_shop).scope(variant)
    variant
  end

  let!(:order_cycle) do
    cycle = OrderCycle.create!(
      name: "Mary's Online Shop OC",
      orders_open_at: 1.day.ago,
      orders_close_at: 1.month.from_now,
      coordinator: marys_online_shop
    )
    cycle.coordinator_fees << marys_online_shop.enterprise_fees.first

    incoming = Exchange.create!(
      order_cycle: cycle, sender: freddys_farm_shop, receiver: cycle.coordinator, incoming: true
    )
    outgoing = Exchange.create!(
      order_cycle: cycle, sender: cycle.coordinator, receiver: marys_online_shop, incoming: false
    )

    freddys_farm_shop.supplied_products.each do |product|
      incoming.variants << product.variants.first
      outgoing.variants << product.variants.first
    end

    cycle
  end

  let(:order) do
    create(
      :order,
      distributor: marys_online_shop,
      order_cycle: order_cycle,
      ship_address: create(:address)
    )
  end

  before do
    order.add_variant(beef_variant, 1, nil, order.currency)
    order.add_variant(apple_variant_2, 1, nil, order.currency)
    order.add_variant(apple_variant_5, 5, nil, order.currency)
    order.add_variant(apple_variant_8, 3, nil, order.currency)

    order.create_proposed_shipments
    order.finalize!

    order.completed_at = Time.zone.parse("2020-02-05 00:00:00 +1100")
    order.save

    allow(controller).to receive(:spree_current_user).and_return(mary)
  end

  it 'returns the right CSV' do
    spree_post :orders_and_fulfillment, {
      q: {
        completed_at_gt: "2020-01-11 00:00:00 +1100",
        completed_at_lt: "2020-02-12 00:00:00 +1100",
        distributor_id_in: [marys_online_shop.id],
        order_cycle_id_in: [""]
      },
      report_type: "order_cycle_distributor_totals_by_supplier",
      csv: true
    }

    csv_report = assigns(:csv_report)
    report_lines = csv_report.split("\n")
    csv_fixture_lines = csv.split("\n")

    expect(report_lines[0]).to eq(csv_fixture_lines[0])
    expect(report_lines[1]).to eq(csv_fixture_lines[1])
    expect(report_lines[2]).to eq(csv_fixture_lines[2])
    expect(report_lines[3]).to eq(csv_fixture_lines[3])
    expect(report_lines[4]).to eq(csv_fixture_lines[4])
    expect(report_lines[5]).to eq(csv_fixture_lines[5])
  end
end
