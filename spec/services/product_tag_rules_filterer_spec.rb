# frozen_string_literal: true

require "spec_helper"

describe ProductTagRulesFilterer do
  describe "filtering by tag rules" do
    let!(:distributor) { create(:distributor_enterprise) }
    let(:product) { create(:product, supplier: distributor) }
    let(:v1) { create(:variant, product: product) }
    let(:v2) { create(:variant, product: product) }
    let(:v3) { create(:variant, product: product) }
    let(:v4) { create(:variant, product: product) }
    let(:variant_hidden_by_default) { create(:variant_override, variant: v1, hub: distributor) }
    let(:variant_hidden_by_rule) { create(:variant_override, variant: v2, hub: distributor) }
    let(:variant_shown_by_rule) { create(:variant_override, variant: v3, hub: distributor) }
    let(:variant_hidden_for_another_customer) {
      create(:variant_override, variant: v4, hub: distributor)
    }
    let(:customer) { create(:customer, enterprise: distributor) }
    let(:variants_relation) {
      Spree::Variant.joins(:product).where("spree_products.supplier_id = ?", distributor.id)
    }
    let(:default_hide_rule) {
      create(:filter_products_tag_rule,
             enterprise: distributor,
             is_default: true,
             preferred_variant_tags: "hide_these_variants_from_everyone",
             preferred_matched_variants_visibility: "hidden")
    }
    let!(:hide_rule) {
      create(:filter_products_tag_rule,
             enterprise: distributor,
             preferred_variant_tags: "hide_these_variants",
             preferred_customer_tags: "hide_from_these_customers",
             preferred_matched_variants_visibility: "hidden" )
    }
    let!(:show_rule) {
      create(:filter_products_tag_rule,
             enterprise: distributor,
             preferred_variant_tags: "show_these_variants",
             preferred_customer_tags: "show_for_these_customers",
             preferred_matched_variants_visibility: "visible" )
    }
    let!(:non_applicable_rule) {
      create(:filter_products_tag_rule,
             enterprise: distributor,
             preferred_variant_tags: "hide_these_other_variants",
             preferred_customer_tags: "hide_from_other_customers",
             preferred_matched_variants_visibility: "hidden" )
    }
    let(:filterer) { described_class.new(distributor, customer, variants_relation) }

    context "when the distributor has no rules" do
      it "returns the relation unchanged" do
        expect(filterer.call).to eq variants_relation
      end
    end

    describe "#customer_applicable_rules" do
      it "returns a list of tags that apply to the current customer" do
        customer.update_attribute(:tag_list, show_rule.preferred_customer_tags)

        customer_applicable_rules = filterer.__send__(:customer_applicable_rules)
        expect(customer_applicable_rules).to eq [show_rule]
      end
    end

    describe "#overrides_to_hide" do
      context "with default rules" do
        it "lists overrides tagged as hidden for this customer" do
          variant_hidden_by_default.update_attribute(:tag_list,
                                                     default_hide_rule.preferred_variant_tags)

          overrides_to_hide = filterer.__send__(:overrides_to_hide)
          expect(overrides_to_hide).to eq [variant_hidden_by_default.id]
        end
      end

      context "with default and specific rules" do
        it "lists overrides tagged as hidden for this customer" do
          customer.update_attribute(:tag_list, hide_rule.preferred_customer_tags)
          variant_hidden_by_default.update_attribute(:tag_list,
                                                     default_hide_rule.preferred_variant_tags)
          variant_hidden_by_rule.update_attribute(:tag_list, hide_rule.preferred_variant_tags)
          variant_hidden_for_another_customer
            .update_attribute(:tag_list, non_applicable_rule.preferred_variant_tags)

          overrides_to_hide = filterer.__send__(:overrides_to_hide)
          expect(overrides_to_hide).to include variant_hidden_by_default.id,
                                               variant_hidden_by_rule.id
        end
      end
    end

    describe "#overrides_to_show" do
      it "lists overrides tagged as visible for this customer" do
        customer.update_attribute(:tag_list, show_rule.preferred_customer_tags)
        variant_shown_by_rule.update_attribute(:tag_list, show_rule.preferred_variant_tags)

        overrides_to_show = filterer.__send__(:overrides_to_show)
        expect(overrides_to_show).to eq [variant_shown_by_rule.id]
      end
    end
  end
end
