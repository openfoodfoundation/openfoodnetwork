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
end
