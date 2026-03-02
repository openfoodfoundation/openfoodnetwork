# frozen_string_literal: true

RSpec.describe TagRule::FilterOrderCycles do
  let(:tag_rule) {
    build(:filter_order_cycles_tag_rule, preferred_exchange_tags: order_cycle_tags, enterprise:)
  }
  let(:order_cycle_tags) { "" }
  let(:enterprise) { build(:enterprise) }

  describe "#tags" do
    let(:order_cycle_tags) { "my_tag" }

    it "return the exchange tags" do
      expect(tag_rule.tags).to eq("my_tag")
    end
  end

  describe "#tags_match?" do
    context "when the exchange is nil" do
      before do
        allow(tag_rule).to receive(:exchange_for) { nil }
      end

      it "returns false" do
        expect(tag_rule.tags_match?(nil)).to be false
      end
    end

    context "when the exchange is not nil" do
      let(:order_cycle) { create(:simple_order_cycle, distributors: [enterprise]) }

      before do
        exchange = order_cycle.exchanges.outgoing.first
        exchange.tag_list = "member,local,volunteer"
        exchange.save!
      end

      context "when the rule has no preferred exchange tags specified" do
        it { expect(tag_rule.tags_match?(order_cycle)).to be false }
      end

      context "when the rule has preferred exchange tags specified that match ANY exchange tags" do
        let(:order_cycle_tags) { "wholesale,some_tag,member" }

        it { expect(tag_rule.tags_match?(order_cycle)).to be true }
      end

      context "when the rule has preferred exchange tags specified that match NO exchange tags" do
        let(:order_cycle_tags) { "wholesale,some_tag,some_other_tag" }

        it { expect(tag_rule.tags_match?(order_cycle)).to be false }
      end
    end
  end

  describe "#reject_matched?" do
    it "return false with default visibility (visible)" do
      expect(tag_rule.reject_matched?).to be false
    end

    context "when visiblity is set to hidden" do
      let(:tag_rule) {
        build(:filter_order_cycles_tag_rule, preferred_matched_order_cycles_visibility: "hidden")
      }

      it { expect(tag_rule.reject_matched?).to be true }
    end
  end
end
