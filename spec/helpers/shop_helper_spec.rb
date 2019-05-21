require 'spec_helper'
describe ShopHelper, type: :helper do
  it "should build order cycle select options" do
    d = create(:distributor_enterprise)
    o1 = create(:simple_order_cycle, distributors: [d])
    allow(helper).to receive(:current_distributor).and_return d

    expect(helper.order_cycles_name_and_pickup_times([o1])).to eq([[helper.pickup_time(o1), o1.id]])
  end
end
