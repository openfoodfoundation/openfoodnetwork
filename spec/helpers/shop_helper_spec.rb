require 'spec_helper'
describe ShopHelper, type: :helper do
  it "should build order cycle select options" do
    d = create(:distributor_enterprise)
    o1 = create(:simple_order_cycle, distributors: [d])
    allow(helper).to receive(:current_distributor).and_return d

    expect(helper.order_cycles_name_and_pickup_times([o1])).to eq([[helper.pickup_time(o1), o1.id]])
  end

  describe "shop_tabs" do
    context "distributor with groups" do
      let(:group) { create(:enterprise_group) }
      let(:distributor) { create(:distributor_enterprise, groups: [group]) }
      let(:expectation) {
        [
          {name: "home", show: false, title: "Home"},
          {name: "shop", show: true, title: "Shop"},
          {name: "about", show: true, title: "About"},
          {name: "producers", show: true, title: "Producers"},
          {name: "contact", show: true, title: "Contact"},
          {name: "groups", show: true, title: "Groups"}
        ]
      }

      before do
        allow(helper).to receive(:current_distributor).and_return distributor
      end

      it "should return the groups tab" do
        expect(helper.shop_tabs).to eq(expectation) #
      end
    end

    context "distributor without groups" do
      let(:distributor) { create(:distributor_enterprise) }
      let(:expectation) {
        [
          {name: "home", show: false, title: "Home"},
          {name: "shop", show: true, title: "Shop"},
          {name: "about", show: true, title: "About"},
          {name: "producers", show: true, title: "Producers"},
          {name: "contact", show: true, title: "Contact"},
          {name: "groups", show: false, title: "Groups"}
        ]
      }

      before do
        allow(helper).to receive(:current_distributor).and_return distributor
      end

      it "should not return the groups tab" do
        expect(helper.shop_tabs).to eq(expectation)
      end
    end
  end
end
