# frozen_string_literal: true

RSpec.describe TagRule::FilterVariants do
  let(:tag_rule) { build(:filter_variants_tag_rule, preferred_variant_tags: variant_tags) }
  let(:variant_tags) { "" }

  describe "#tags" do
    let(:variant_tags) { "my_tag" }

    it "return the variants tags" do
      expect(tag_rule.tags).to eq("my_tag")
    end
  end

  describe "#tags_match?" do
    let(:variant_tags) { "my_tag" }

    context "when the variant is nil" do
      it "returns false" do
        expect(tag_rule.tags_match?(nil)).to be false
      end
    end

    context "when the variant is not nil" do
      let(:variant_object) { { "tag_list" => ["member", "local", "volunteer"] } }

      context "when the rule has no preferred variant tags specified" do
        it { expect(tag_rule.tags_match?(variant_object)).to be false }
      end

      context "when the rule has preferred variant tags specified that match ANY variant tags" do
        let(:variant_tags) { "wholesale,some_tag,member" }

        it { expect(tag_rule.tags_match?(variant_object)).to be true }
      end

      context "when the rule has preferred variant tags specified that match NO variant tags" do
        let(:variant_tags) { "wholesale,some_tag,some_other_tag" }

        it { expect(tag_rule.tags_match?(variant_object)).to be false }
      end
    end
  end

  describe "#reject_matched?" do
    it "return false with default visibility (visible)" do
      expect(tag_rule.reject_matched?).to be false
    end

    context "when visiblity is set to hidden" do
      let(:tag_rule) {
        build(:filter_variants_tag_rule, preferred_matched_variants_visibility: "hidden")
      }

      it { expect(tag_rule.reject_matched?).to be true }
    end
  end
end
