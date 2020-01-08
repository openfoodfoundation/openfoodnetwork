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
          { name: 'about', title: t(:shopping_tabs_about, distributor: distributor.name), cols: 6 },
          { name: 'producers', title: t(:label_producers), cols: 2 },
          { name: 'contact', title: t(:shopping_tabs_contact), cols: 2 },
          { name: 'groups', title: t(:label_groups), cols: 2 }
        ]
      }

      before do
        allow(helper).to receive(:current_distributor).and_return distributor
      end

      it "should return the groups tab" do
        expect(helper.shop_tabs).to eq(expectation)
      end
    end

    context "distributor without groups" do
      let(:distributor) { create(:distributor_enterprise) }
      let(:expectation) {
        [
          { name: 'about', title: t(:shopping_tabs_about, distributor: distributor.name), cols: 4 },
          { name: 'producers', title: t(:label_producers), cols: 4 },
          { name: 'contact', title: t(:shopping_tabs_contact), cols: 4 }
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
