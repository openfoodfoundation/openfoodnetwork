# frozen_string_literal: true

require 'spec_helper'

describe Spree::OrdersHelper, type: :helper do
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
            before { allow(current_distributor).to receive(:allow_order_changes?) { true } }
            it { expect(helper.changeable_orders).to eq "some_orders" }
          end

          context "when the current_distributor does not allow order changes" do
            before { allow(current_distributor).to receive(:allow_order_changes?) { false } }
            it { expect(helper.changeable_orders).to eq [] }
          end
        end

        context "when a current_order_cycle is not defined" do
          let(:current_order_cycle) { nil }
          it { expect(helper.changeable_orders).to eq [] }
        end
      end

      context "when a current_distributor is not defined" do
        let(:current_distributor) { nil }
        it { expect(helper.changeable_orders).to eq [] }
      end
    end

    context "when spree_current_user is not defined" do
      let(:spree_current_user) { nil }
      it { expect(helper.changeable_orders).to eq [] }
    end
  end
end
