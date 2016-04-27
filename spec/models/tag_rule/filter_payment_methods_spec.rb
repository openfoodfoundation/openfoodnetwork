require 'spec_helper'

describe TagRule::FilterPaymentMethods, type: :model do
  let!(:tag_rule) { create(:filter_payment_methods_tag_rule) }

  describe "determining whether tags match for a given payment method" do
    context "when the payment method is nil" do

      it "returns false" do
        expect(tag_rule.send(:tags_match?, nil)).to be false
      end
    end

    context "when the payment method is not nil" do
      let(:payment_method) { create(:payment_method, tag_list: ["member","local","volunteer"]) }

      context "when the rule has no preferred payment method tags specified" do
        before { allow(tag_rule).to receive(:preferred_payment_method_tags) { "" } }
        it { expect(tag_rule.send(:tags_match?, payment_method)).to be false }
      end

      context "when the rule has preferred customer tags specified that match ANY of the customer tags" do
        before { allow(tag_rule).to receive(:preferred_payment_method_tags) { "wholesale,some_tag,member" } }
        it { expect(tag_rule.send(:tags_match?, payment_method)).to be true }
      end

      context "when the rule has preferred customer tags specified that match NONE of the customer tags" do
        before { allow(tag_rule).to receive(:preferred_payment_method_tags) { "wholesale,some_tag,some_other_tag" } }
        it { expect(tag_rule.send(:tags_match?, payment_method)).to be false }
      end
    end
  end

  describe "applying the rule" do
    # Assume that all validation is done by the TagRule base class

    let(:sm1) { create(:payment_method, tag_list: ["tag1", "something", "somethingelse"]) }
    let(:sm2) { create(:payment_method, tag_list: ["tag2"]) }
    let(:sm3) { create(:payment_method, tag_list: ["tag3"]) }
    let!(:payment_methods) { [sm1, sm2, sm3] }

    before do
      tag_rule.update_attribute(:preferred_payment_method_tags, "tag2")
      tag_rule.context = {subject: payment_methods}
    end

    context "apply!" do
      context "when showing matching payment methods" do
        before { tag_rule.update_attribute(:preferred_matched_payment_methods_visibility, "visible") }
        it "does nothing" do
          tag_rule.send(:apply!)
          expect(payment_methods).to eq [sm1, sm2, sm3]
        end
      end

      context "when hiding matching payment methods" do
        before { tag_rule.update_attribute(:preferred_matched_payment_methods_visibility, "hidden") }
        it "removes matching payment methods from the list" do
          tag_rule.send(:apply!)
          expect(payment_methods).to eq [sm1, sm3]
        end
      end
    end

    context "apply_default!" do
      context "when showing matching payment methods" do
        before { tag_rule.update_attribute(:preferred_matched_payment_methods_visibility, "visible") }
        it "remove matching payment methods from the list" do
          tag_rule.send(:apply_default!)
          expect(payment_methods).to eq [sm1, sm3]
        end
      end

      context "when hiding matching payment methods" do
        before { tag_rule.update_attribute(:preferred_matched_payment_methods_visibility, "hidden") }
        it "does nothing" do
          tag_rule.send(:apply_default!)
          expect(payment_methods).to eq [sm1, sm2, sm3]
        end
      end
    end
  end
end
