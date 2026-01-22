# frozen_string_literal: true

RSpec.describe TagRule::FilterPaymentMethods do
  let(:tag_rule) {
    build(:filter_payment_methods_tag_rule, preferred_payment_method_tags: payment_method_tags)
  }
  let(:payment_method_tags) { "" }

  describe "#tags" do
    let(:payment_method_tags) { "my_tag" }

    it "return the payment method tags" do
      expect(tag_rule.tags).to eq("my_tag")
    end
  end

  describe "#tags_match?" do
    context "when the payment method is nil" do
      it "returns false" do
        expect(tag_rule.tags_match?(nil)).to be false
      end
    end

    context "when the payment method is not nil" do
      let(:payment_method) { build(:payment_method, tag_list: ["member", "local", "volunteer"]) }

      context "when the rule has no preferred payment method tags specified" do
        it { expect(tag_rule.tags_match?(payment_method)).to be false }
      end

      context "when the rule has preferred customer tags specified that match ANY customer tags" do
        let(:payment_method_tags) { "wholesale,some_tag,member" }

        it { expect(tag_rule.tags_match?(payment_method)).to be true }
      end

      context "when the rule has preferred customer tags specified that match NO customer tags" do
        let(:payment_method_tags) { "wholesale,some_tag,some_other_tag" }

        it { expect(tag_rule.tags_match?(payment_method)).to be false }
      end
    end
  end

  describe "#reject_matched?" do
    it "return false with default visibility (visible)" do
      expect(tag_rule.reject_matched?).to be false
    end

    context "when visiblity is set to hidden" do
      let(:tag_rule) {
        build(:filter_payment_methods_tag_rule,
              preferred_matched_payment_methods_visibility: "hidden")
      }

      it { expect(tag_rule.reject_matched?).to be true }
    end
  end
end
