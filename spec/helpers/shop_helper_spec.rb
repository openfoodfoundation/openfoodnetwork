# frozen_string_literal: false

require 'spec_helper'
describe ShopHelper, type: :helper do
  describe "shop_tabs" do
    context "distributor with groups" do
      let(:group) { create(:enterprise_group) }
      let(:distributor) { create(:distributor_enterprise, groups: [group]) }

      before do
        allow(helper).to receive(:current_distributor).and_return distributor
      end

      it "should return the groups tab" do
        expect(helper.shop_tabs).to include(name: "groups", show: true, title: "Groups")
      end
    end

    context "distributor without groups" do
      let(:distributor) { create(:distributor_enterprise) }

      before do
        allow(helper).to receive(:current_distributor).and_return distributor
      end

      it "should not return the groups tab" do
        expect(helper.shop_tabs).to_not include(name: "groups", show: true, title: "Groups")
      end
    end

    context "distributor with shopfront message" do
      let(:distributor) { create(:distributor_enterprise, preferred_shopfront_message: "Hello!") }

      before do
        allow(helper).to receive(:current_distributor).and_return distributor
      end

      it "should show the home tab" do
        expect(helper.shop_tabs).to include(name: "home", show: true, title: "Home", default: true)
      end
    end
  end
end
