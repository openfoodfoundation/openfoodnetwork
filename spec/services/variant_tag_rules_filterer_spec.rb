# frozen_string_literal: true

RSpec.describe VariantTagRulesFilterer do
  subject(:filterer) { described_class.new(distributor:, customer:, variants_relation:) }

  let(:distributor) { create(:distributor_enterprise) }
  let(:product) { create(:product) }
  let!(:variant_hidden_by_default) { create(:variant, product:, supplier: distributor) }
  let!(:variant_hidden_by_rule) { create(:variant, product:, supplier: distributor) }
  let!(:variant_shown_by_rule) { create(:variant, product:, supplier: distributor) }
  let!(:variant_hidden_for_another_customer) { create(:variant, product:, supplier: distributor) }
  let(:customer) { create(:customer, enterprise: distributor) }
  let(:variants_relation) { Spree::Variant.where(supplier: distributor) }

  describe "#call" do
    let!(:hide_rule) {
      create(:filter_variants_tag_rule,
             enterprise: distributor,
             preferred_variant_tags: "hide_these_variants",
             preferred_customer_tags: "hide_from_these_customers",
             preferred_matched_variants_visibility: "hidden" )
    }
    let!(:show_rule) {
      create(:filter_variants_tag_rule,
             enterprise: distributor,
             preferred_variant_tags: "show_these_variants",
             preferred_customer_tags: "show_for_these_customers",
             preferred_matched_variants_visibility: "visible" )
    }
    let!(:non_applicable_rule) {
      create(:filter_variants_tag_rule,
             enterprise: distributor,
             preferred_variant_tags: "hide_these_other_variants",
             preferred_customer_tags: "hide_from_other_customers",
             preferred_matched_variants_visibility: "hidden" )
    }

    context "when the distributor has no rules" do
      it "returns the relation unchanged" do
        expect(filterer.call).to eq variants_relation
      end
    end

    context "with hide rule" do
      it "hides the variant matching the rule" do
        customer.update_attribute(:tag_list, hide_rule.preferred_customer_tags)
        variant_hidden_by_rule.update_attribute(:tag_list, hide_rule.preferred_variant_tags)

        expect(filterer.call).not_to include(variant_hidden_by_rule)
      end

      context "with mutiple conflicting rules" do
        it "applies the show rule" do
          # Customer has show rule tag and hide rule tag
          customer.update_attribute(
            :tag_list, [hide_rule.preferred_customer_tags, show_rule.preferred_customer_tags]
          )
          # Variant has show rule tag and hide rule tag
          variant_hidden_by_rule.update_attribute(
            :tag_list, [hide_rule.preferred_variant_tags, show_rule.preferred_variant_tags,]
          )
          expect(filterer.call).to include(variant_hidden_by_rule)
        end
      end
    end

    context "with variant hidden by default" do
      let(:default_hide_rule) {
        create(:filter_variants_tag_rule,
               enterprise: distributor,
               is_default: true,
               preferred_variant_tags: "hide_these_variants_from_everyone",
               preferred_matched_variants_visibility: "hidden")
      }

      before do
        variant_hidden_by_default.update_attribute(
          :tag_list, default_hide_rule.preferred_variant_tags
        )
      end

      it "excludes variant hidden by default" do
        expect(filterer.call).not_to include(variant_hidden_by_default)
      end

      context "with variant rule overriding default rule" do
        it "includes variant hidden by default" do
          customer.update_attribute(:tag_list, show_rule.preferred_customer_tags)
          # Variant has default rule tag and show rule tag
          variant_hidden_by_default.update_attribute(
            :tag_list, [default_hide_rule.preferred_variant_tags, show_rule.preferred_variant_tags]
          )

          expect(filterer.call).to include(variant_hidden_by_default)
        end

        context "with mutiple conflicting rules applying to same variant" do
          it "applies the show rule" do
            # customer has show rule and hide rule tag
            customer.update_attribute(
              :tag_list, [show_rule.preferred_customer_tags, hide_rule.preferred_customer_tags]
            )

            # Variant has default rule tag and show rule tag and hide rule tag
            variant_hidden_by_default.update_attribute(
              :tag_list,
              [default_hide_rule.preferred_variant_tags, show_rule.preferred_variant_tags,
               hide_rule.preferred_variant_tags]
            )

            expect(filterer.call).to include(variant_hidden_by_default)
          end
        end
      end
    end
  end
end
