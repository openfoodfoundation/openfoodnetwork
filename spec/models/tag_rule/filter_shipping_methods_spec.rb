# frozen_string_literal: true

RSpec.describe TagRule::FilterShippingMethods do
  let(:tag_rule) {
    build(:filter_shipping_methods_tag_rule, preferred_shipping_method_tags: shipping_method_tags)
  }
  let(:shipping_method_tags) { "" }

  describe "#tags" do
    let(:shipping_method_tags) { "my_tag" }

    it "return the shipping method tags" do
      expect(tag_rule.tags).to eq("my_tag")
    end
  end

  describe "#tags_match?" do
    context "when the shipping method is nil" do
      it "returns false" do
        expect(tag_rule.tags_match?(nil)).to be false
      end
    end

    context "when the shipping method is not nil" do
      let(:shipping_method) {
        build(:shipping_method, tag_list: ["member", "local", "volunteer"])
      }

      context "when the rule has no preferred shipping method tags specified" do
        it { expect(tag_rule.tags_match?(shipping_method)).to be false }
      end

      context "when rule has preferred customer tags specified that match ANY customer tags" do
        let(:shipping_method_tags) { "wholesale,some_tag,member" }

        it { expect(tag_rule.tags_match?(shipping_method)).to be true }
      end

      context "when rule has preferred customer tags specified that match NO customer tags" do
        let(:shipping_method_tags) { "wholesale,some_tag,some_other_tag" }

        it { expect(tag_rule.tags_match?(shipping_method)).to be false }
      end
    end
  end

  describe "#reject_matched?" do
    it "return false with default visibility (visible)" do
      expect(tag_rule.reject_matched?).to be false
    end

    context "when visiblity is set to hidden" do
      let(:tag_rule) {
        build(:filter_shipping_methods_tag_rule,
              preferred_matched_shipping_methods_visibility: "hidden")
      }

      it { expect(tag_rule.reject_matched?).to be true }
    end
  end
end
