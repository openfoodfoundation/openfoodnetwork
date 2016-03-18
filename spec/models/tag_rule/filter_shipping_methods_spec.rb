require 'spec_helper'

describe TagRule::DiscountOrder, type: :model do
  let!(:tag_rule) { create(:filter_shipping_method_tag_rule) }

  describe "determining whether tags match for a given shipping method" do
    context "when the shipping method is nil" do

      it "returns false" do
        expect(tag_rule.send(:tags_match?, nil)).to be false
      end
    end

    context "when the shipping method is not nil" do
      let(:shipping_method) { create(:shipping_method, tag_list: ["member","local","volunteer"]) }

      context "when the rule has no preferred shipping method tags specified" do
        before { allow(tag_rule).to receive(:preferred_shipping_method_tags) { "" } }
        it { expect(tag_rule.send(:tags_match?, shipping_method)).to be false }
      end

      context "when the rule has preferred customer tags specified that match ANY of the customer tags" do
        before { allow(tag_rule).to receive(:preferred_shipping_method_tags) { "wholesale,some_tag,member" } }
        it { expect(tag_rule.send(:tags_match?, shipping_method)).to be true }
      end

      context "when the rule has preferred customer tags specified that match NONE of the customer tags" do
        before { allow(tag_rule).to receive(:preferred_shipping_method_tags) { "wholesale,some_tag,some_other_tag" } }
        it { expect(tag_rule.send(:tags_match?, shipping_method)).to be false }
      end
    end
  end

  describe "applying the rule" do
    # Assume that all validation is done by the TagRule base class

    let(:sm1) { create(:shipping_method, tag_list: ["tag1", "something", "somethingelse"]) }
    let(:sm2) { create(:shipping_method, tag_list: ["tag2"]) }
    let(:sm3) { create(:shipping_method, tag_list: ["tag3"]) }
    let!(:shipping_methods) { [sm1, sm2, sm3] }

    before do
      tag_rule.update_attribute(:preferred_shipping_method_tags, "tag2")
      tag_rule.set_context(shipping_methods, nil)
    end

    context "apply!" do
      context "when showing matching shipping methods" do
        before { tag_rule.update_attribute(:preferred_matched_shipping_methods_visibility, "visible") }
        it "does nothing" do
          tag_rule.send(:apply!)
          expect(shipping_methods).to eq [sm1, sm2, sm3]
        end
      end

      context "when hiding matching shipping methods" do
        before { tag_rule.update_attribute(:preferred_matched_shipping_methods_visibility, "hidden") }
        it "removes matching shipping methods from the list" do
          tag_rule.send(:apply!)
          expect(shipping_methods).to eq [sm1, sm3]
        end
      end
    end

    context "apply_default!" do
      context "when showing matching shipping methods" do
        before { tag_rule.update_attribute(:preferred_matched_shipping_methods_visibility, "visible") }
        it "remove matching shipping methods from the list" do
          tag_rule.send(:apply_default!)
          expect(shipping_methods).to eq [sm1, sm3]
        end
      end

      context "when hiding matching shipping methods" do
        before { tag_rule.update_attribute(:preferred_matched_shipping_methods_visibility, "hidden") }
        it "does nothing" do
          tag_rule.send(:apply_default!)
          expect(shipping_methods).to eq [sm1, sm2, sm3]
        end
      end
    end
  end
end
