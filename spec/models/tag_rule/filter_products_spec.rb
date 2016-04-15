require 'spec_helper'

describe TagRule::FilterProducts, type: :model do
  let!(:tag_rule) { create(:filter_products_tag_rule) }

  describe "determining whether tags match for a given variant" do
    context "when the variantm is nil" do

      it "returns false" do
        expect(tag_rule.send(:tags_match?, nil)).to be false
      end
    end

    context "when the variant is not nil" do
      let(:variant_object) { { tag_list: ["member","local","volunteer"] } }

      context "when the rule has no preferred variant tags specified" do
        before { allow(tag_rule).to receive(:preferred_variant_tags) { "" } }
        it { expect(tag_rule.send(:tags_match?, variant_object)).to be false }
      end

      context "when the rule has preferred variant tags specified that match ANY of the variant tags" do
        before { allow(tag_rule).to receive(:preferred_variant_tags) { "wholesale,some_tag,member" } }
        it { expect(tag_rule.send(:tags_match?, variant_object)).to be true }
      end

      context "when the rule has preferred variant tags specified that match NONE of the variant tags" do
        before { allow(tag_rule).to receive(:preferred_variant_tags) { "wholesale,some_tag,some_other_tag" } }
        it { expect(tag_rule.send(:tags_match?, variant_object)).to be false }
      end
    end
  end

  describe "applying the rule" do
    # Assume that all validation is done by the TagRule base class

    let(:product1) { { name: "product1", variants: [{ name: "v1", tag_list: ["tag1", "something", "somethingelse"]}] } }
    let(:product2) { { name: "product2", variants: [{ name: "v2", tag_list: ["tag2"]}] } }
    let(:product3) { { name: "product3", variants: [{ name: "v3", tag_list: ["tag3"]}] } }
    let!(:product_hash) { [product1, product2, product3] }

    before do
      tag_rule.update_attribute(:preferred_variant_tags, "tag2")
      tag_rule.set_context(product_hash, nil)
    end

    context "apply!" do
      context "when showing matching variants" do
        before { tag_rule.update_attribute(:preferred_matched_variants_visibility, "visible") }
        it "does nothing" do
          tag_rule.send(:apply!)
          expect(product_hash).to eq [product1, product2, product3]
        end
      end

      context "when hiding matching variants" do
        before { tag_rule.update_attribute(:preferred_matched_variants_visibility, "hidden") }
        it "removes matching variants from the list" do
          tag_rule.send(:apply!)
          expect(product_hash).to eq [product1, product3]
        end
      end
    end

    context "apply_default!" do
      context "when showing matching variants" do
        before { tag_rule.update_attribute(:preferred_matched_variants_visibility, "visible") }
        it "remove matching variants from the list" do
          tag_rule.send(:apply_default!)
          expect(product_hash).to eq [product1, product3]
        end
      end

      context "when hiding matching variants" do
        before { tag_rule.update_attribute(:preferred_matched_variants_visibility, "hidden") }
        it "does nothing" do
          tag_rule.send(:apply_default!)
          expect(product_hash).to eq [product1, product2, product3]
        end
      end
    end
  end
end
