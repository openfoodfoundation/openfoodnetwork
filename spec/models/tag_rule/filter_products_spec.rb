# frozen_string_literal: true

require 'spec_helper'

describe TagRule::FilterProducts, type: :model do
  let!(:tag_rule) { build_stubbed(:filter_products_tag_rule) }

  describe "determining whether tags match for a given variant" do
    context "when the variant is nil" do
      it "returns false" do
        expect(tag_rule.send(:tags_match?, nil)).to be false
      end
    end

    context "when the variant is not nil" do
      let(:variant_object) { { "tag_list" => ["member", "local", "volunteer"] } }

      context "when the rule has no preferred variant tags specified" do
        before { allow(tag_rule).to receive(:preferred_variant_tags) { "" } }
        it { expect(tag_rule.send(:tags_match?, variant_object)).to be false }
      end

      context "when the rule has preferred variant tags specified that match ANY variant tags" do
        before {
          allow(tag_rule).to receive(:preferred_variant_tags) {
                               "wholesale,some_tag,member"
                             }
        }
        it { expect(tag_rule.send(:tags_match?, variant_object)).to be true }
      end

      context "when the rule has preferred variant tags specified that match NO variant tags" do
        before {
          allow(tag_rule).to receive(:preferred_variant_tags) {
                               "wholesale,some_tag,some_other_tag"
                             }
        }
        it { expect(tag_rule.send(:tags_match?, variant_object)).to be false }
      end
    end
  end
end
