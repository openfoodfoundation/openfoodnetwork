require 'spec_helper'
require "tasks/sample_data/user_factory"
require "tasks/sample_data/fee_factory"
require "tasks/sample_data/order_cycle_factory"

describe Spree::Admin::ReportsController, type: :controller do
  let!(:producer) {
    create(
      :enterprise,
      name: "Freddy's Farm Shop",
      is_primary_producer: true,
      sells: 'own'
    )
  }
  let!(:distributor) {
    create(
      :distributor_enterprise,
      name: "Mary's Online Shop",
    )
  }

  let(:apple) { create(:product, supplier: producer, name: 'Fuji Apple') }
  let(:apple_5) { create(:variant, product: apple, unit_value: 5.0, price: 12.0, weight: 0.01) }

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

  let(:mary) { UserFactory.new.send(:create_user, 'Mary Retailer') }
  let(:marys_online_shop) do
    Enterprise.create_with(
      name: "Mary's Online Shop",
      owner: mary,
      is_primary_producer: false,
      sells: "any",
      address: address("20 Galvin Street, Altona, 3018")
    ).find_or_create_by_name!("Mary's Online Shop")
  end

  before do
    freddy = UserFactory.new.send(:create_user, 'Freddy Shop Farmer') 

    freddys_farm_shop = Enterprise.create_with(
      name: "Freddy's Farm Shop",
      owner: freddy,
      is_primary_producer: true,
      sells: "own",
      address: address("72 Lake Road, Blackburn, 3130")
    ).find_or_create_by_name!("Freddy's Farm Shop")
    FeeFactory.new.create_samples([marys_online_shop, freddys_farm_shop])

    OrderCycleFactory.new.send(
      :create_order_cycle,
      "Mary's Online Shop OC",
      "Mary's Online Shop",
      ["Fred's Farm", "Freddy's Farm Shop", "Fredo's Farm Hub"],
      ["Mary's Online Shop"],
      receival_instructions: "Please shut the gate.",
      pickup_time: "midday"
    )

    order = create(
      :order,
      distributor: marys_online_shop,
      order_cycle: OrderCycle.find_by_name("Mary's Online Shop OC")
    )
    order.line_items << create(:line_item, variant: apple_5, quantity: 5)
    order.finalize!
    order.completed_at = Time.zone.parse("2020-02-05 00:00:00 +1100")
    order.save

    marys_user = mary.second
    marys_online_shop.enterprise_roles.create!(user: marys_user)
    allow(controller).to receive(:spree_current_user).and_return(marys_user)
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

    expect(assigns(:csv_report)).to eq(csv)
  end
end
