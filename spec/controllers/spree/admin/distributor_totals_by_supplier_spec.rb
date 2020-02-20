require 'spec_helper'
require "tasks/sample_data/user_factory"
require "tasks/sample_data/fee_factory"
require "tasks/sample_data/order_cycle_factory"
require "tasks/sample_data/product_factory"
require "tasks/sample_data/taxon_factory"

describe Spree::Admin::ReportsController, type: :controller do
  before do
    DefaultShippingCategory.find_or_create
    DefaultStockLocation.create!
    TaxonFactory.new.create_samples
  end

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

  let(:country) do
    Spree::Country.find_by_iso(ENV.fetch('DEFAULT_COUNTRY_CODE'))
  end

  def address(string)
    state = country.states.first
    parts = string.split(", ")
    Spree::Address.new(
      address1: parts[0],
      city: parts[1],
      zipcode: parts[2],
      state: state,
      country: country
    )
  end

  let(:meat) { Spree::Taxon.find_by_name('Meat and Fish') }
  let(:fruit) { Spree::Taxon.find_by_name('Fruit') }

  let(:mary) { UserFactory.new.send(:create_user, 'Mary Retailer').second }
  let(:marys_online_shop) do
    Enterprise.create!(
      name: "Mary's Online Shop",
      owner: mary,
      is_primary_producer: false,
      sells: "any",
      address: address("20 Galvin Street, Altona, 3018")
    )
  end

  let(:freddy) { UserFactory.new.send(:create_user, 'Freddy Shop Farmer').second }
  let(:freddys_farm_shop) do
    Enterprise.create!(
      name: "Freddy's Farm Shop",
      owner: freddy,
      is_primary_producer: true,
      sells: "own",
      address: address("72 Lake Road, Blackburn, 3130")
    )
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
    product.variants.first.update_attribute :on_demand, true

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

  before do
    FeeFactory.new.create_samples([marys_online_shop, freddys_farm_shop])

    OrderCycleFactory.new.send(
      :create_order_cycle,
      "Mary's Online Shop OC",
      "Mary's Online Shop",
      ["Freddy's Farm Shop"],
      ["Mary's Online Shop"],
      receival_instructions: "Please shut the gate.",
      pickup_time: "midday"
    )

    order = create(
      :order,
      distributor: marys_online_shop,
      order_cycle: OrderCycle.find_by_name("Mary's Online Shop OC")
    )

    beef_variant = beef.variants.first
    OpenFoodNetwork::ScopeVariantToHub.new(marys_online_shop).scope(beef_variant)

    order.add_variant(beef_variant, 1, nil, order.currency)
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
  end
end
