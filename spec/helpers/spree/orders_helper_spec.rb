# frozen_string_literal: true

RSpec.describe Spree::OrdersHelper do
  describe "#changeable_orders" do
    let(:complete_orders) { double(:complete_orders, where: "some_orders") }

    before do
      allow(Spree::Order).to receive(:complete) { complete_orders }
      allow(helper).to receive(:spree_current_user) { spree_current_user }
      allow(helper).to receive(:current_distributor) { current_distributor }
      allow(helper).to receive(:current_order_cycle) { current_order_cycle }
    end

    context "when a current_user is defined" do
      let(:spree_current_user) { double(:spree_current_user, id: 1) }

      context "when a current_distributor is defined" do
        let(:current_distributor) { double(:current_distributor, id: 1) }

        context "when a current_order_cycle is defined" do
          let(:current_order_cycle) { double(:current_order_cycle, id: 1) }

          context "when the current_distributor allows order changes" do
            before { allow(current_distributor).to receive(:allows_order_changes?) { true } }
            it { expect(helper.changeable_orders).to eq "some_orders" }
          end

          context "when the current_distributor does not allow order changes" do
            before { allow(current_distributor).to receive(:allows_order_changes?) { false } }
            it { expect(helper.changeable_orders).to eq [] }
          end

          context "when a current_distributor is not defined" do
            let(:current_distributor) { nil }
            it { expect(helper.changeable_orders).to eq [] }
          end
        end

        context "when a current_order_cycle is not defined" do
          let(:current_order_cycle) { nil }
          it { expect(helper.changeable_orders).to eq [] }
        end
      end
    end

    context "when spree_current_user is not defined" do
      let(:spree_current_user) { nil }
      it { expect(helper.changeable_orders).to eq [] }
    end
  end

  describe "#addable_orders" do
    let(:user) { create(:user) }
    let(:distributor) { create(:distributor_enterprise, allow_order_additions: true) }
    let(:order_cycle) { create(:simple_order_cycle, distributors: [distributor]) }

    before do
      allow(helper).to receive(:spree_current_user) { user }
      allow(helper).to receive(:current_distributor) { distributor }
      allow(helper).to receive(:current_order_cycle) { order_cycle }
    end

    def place_order(completed_at:)
      create(:completed_order_with_totals, user:, distributor:, order_cycle:, completed_at:)
    end

    it "lists the customer's placed orders in this shop and order cycle, most recent first" do
      older_order = place_order(completed_at: 2.days.ago)
      newer_order = place_order(completed_at: 1.day.ago)

      expect(helper.addable_orders).to eq [newer_order, older_order]
    end

    it "leaves out subscription orders" do
      order = place_order(completed_at: 2.days.ago)
      subscription_order = place_order(completed_at: 1.day.ago)
      create(:proxy_order, order: subscription_order)

      expect(helper.addable_orders).to eq [order]
    end

    it "is empty when the shop only allows other changes" do
      distributor.update!(allow_order_additions: false, allow_order_removals: true)
      place_order(completed_at: 1.day.ago)

      expect(helper.addable_orders).to be_empty
    end

    it "is empty for a guest" do
      place_order(completed_at: 1.day.ago)
      allow(helper).to receive(:spree_current_user) { nil }

      expect(helper.addable_orders).to be_empty
    end
  end
end
