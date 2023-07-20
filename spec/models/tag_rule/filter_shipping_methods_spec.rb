# frozen_string_literal: true

require 'spec_helper'

describe TagRule::FilterShippingMethods, type: :model do
  let!(:tag_rule) { build_stubbed(:filter_shipping_methods_tag_rule) }

  describe "determining whether tags match for a given shipping method" do
    context "when the shipping method is nil" do
      it "returns false" do
        expect(tag_rule.send(:tags_match?, nil)).to be false
      end
    end

    context "when the shipping method is not nil" do
      let(:shipping_method) {
        build_stubbed(:shipping_method, tag_list: ["member", "local", "volunteer"])
      }

      context "when the rule has no preferred shipping method tags specified" do
        before { allow(tag_rule).to receive(:preferred_shipping_method_tags) { "" } }
        it { expect(tag_rule.send(:tags_match?, shipping_method)).to be false }
      end

      context "when rule has preferred customer tags specified that match ANY customer tags" do
        before {
          allow(tag_rule).to receive(:preferred_shipping_method_tags) {
                               "wholesale,some_tag,member"
                             }
        }
        it { expect(tag_rule.send(:tags_match?, shipping_method)).to be true }
      end

      context "when rule has preferred customer tags specified that match NO customer tags" do
        before {
          allow(tag_rule).to receive(:preferred_shipping_method_tags) {
                               "wholesale,some_tag,some_other_tag"
                             }
        }
        it { expect(tag_rule.send(:tags_match?, shipping_method)).to be false }
      end
    end
  end
end
