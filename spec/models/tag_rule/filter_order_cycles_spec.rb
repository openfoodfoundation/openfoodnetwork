require 'spec_helper'

describe TagRule::FilterOrderCycles, type: :model do
  let!(:tag_rule) { create(:filter_order_cycles_tag_rule) }

  describe "determining whether tags match for a given exchange" do
    context "when the exchange is nil" do
      before do
        allow(tag_rule).to receive(:exchange_for) { nil }
      end

      it "returns false" do
        expect(tag_rule.send(:tags_match?, nil)).to be false
      end
    end

    context "when the exchange is not nil" do
      let(:exchange_object) { double(:exchange, tag_list: ["member","local","volunteer"]) }

      before do
        allow(tag_rule).to receive(:exchange_for) { exchange_object }
      end

      context "when the rule has no preferred exchange tags specified" do
        before { allow(tag_rule).to receive(:preferred_exchange_tags) { "" } }
        it { expect(tag_rule.send(:tags_match?, exchange_object)).to be false }
      end

      context "when the rule has preferred exchange tags specified that match ANY of the exchange tags" do
        before { allow(tag_rule).to receive(:preferred_exchange_tags) { "wholesale,some_tag,member" } }
        it { expect(tag_rule.send(:tags_match?, exchange_object)).to be true }
      end

      context "when the rule has preferred exchange tags specified that match NONE of the exchange tags" do
        before { allow(tag_rule).to receive(:preferred_exchange_tags) { "wholesale,some_tag,some_other_tag" } }
        it { expect(tag_rule.send(:tags_match?, exchange_object)).to be false }
      end
    end
  end

  describe "applying the rule" do
    # Assume that all validation is done by the TagRule base class

    let(:enterprise) { create(:distributor_enterprise) }
    let(:order_cycle1) { create(:simple_order_cycle, name: "order_cycle1", exchanges: [ create(:exchange, incoming: false, receiver: enterprise, tag_list: ["tag1", "something", "somethingelse"])]) }
    let(:order_cycle2) { create(:simple_order_cycle, name: "order_cycle2", exchanges: [ create(:exchange, incoming: false, receiver: enterprise, tag_list: ["tag2"])]) }
    let(:order_cycle3) { create(:simple_order_cycle, name: "order_cycle3", exchanges: [ create(:exchange, incoming: false, receiver: enterprise, tag_list: ["tag3"])]) }
    let!(:order_cycle_hash) { [order_cycle1, order_cycle2, order_cycle3] }

    before do
      tag_rule.update_attribute(:preferred_exchange_tags, "tag2")
      tag_rule.context = {subject: order_cycle_hash, shop: enterprise}
    end

    context "apply!" do
      context "when showing matching exchanges" do
        before { tag_rule.update_attribute(:preferred_matched_order_cycles_visibility, "visible") }
        it "does nothing" do
          tag_rule.send(:apply!)
          expect(order_cycle_hash).to eq [order_cycle1, order_cycle2, order_cycle3]
        end
      end

      context "when hiding matching exchanges" do
        before { tag_rule.update_attribute(:preferred_matched_order_cycles_visibility, "hidden") }
        it "removes matching exchanges from the list" do
          tag_rule.send(:apply!)
          expect(order_cycle_hash).to eq [order_cycle1, order_cycle3]
        end
      end
    end

    context "apply_default!" do
      context "when showing matching exchanges" do
        before { tag_rule.update_attribute(:preferred_matched_order_cycles_visibility, "visible") }
        it "remove matching exchanges from the list" do
          tag_rule.send(:apply_default!)
          expect(order_cycle_hash).to eq [order_cycle1, order_cycle3]
        end
      end

      context "when hiding matching exchanges" do
        before { tag_rule.update_attribute(:preferred_matched_order_cycles_visibility, "hidden") }
        it "does nothing" do
          tag_rule.send(:apply_default!)
          expect(order_cycle_hash).to eq [order_cycle1, order_cycle2, order_cycle3]
        end
      end
    end
  end
end
