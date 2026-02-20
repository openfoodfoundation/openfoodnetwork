# frozen_string_literal: true

RSpec.describe Admin::TagRulesController do
  let(:format) { :turbo_stream }

  describe "#destroy" do
    let(:enterprise) { create(:distributor_enterprise) }
    let!(:tag_rule) { create(:filter_order_cycles_tag_rule, enterprise:) }
    let(:params) { { format:, id: tag_rule.id } }

    context "where I don't manage the tag rule enterprise" do
      let(:user) { create(:user) }

      before do
        user.owned_enterprises << create(:enterprise)
        allow(controller).to receive(:spree_current_user) { user }
      end

      it "redirects to unauthorized" do
        spree_delete :destroy, params
        expect(response).to redirect_to unauthorized_path
      end
    end

    context "where I manage the tag rule enterprise" do
      before do
        allow(controller).to receive(:spree_current_user) { enterprise.owner }
      end

      it { expect{ spree_delete :destroy, params }.to change{ TagRule.count }.by(-1) }

      context "when an error happens" do
        it "displays an error flash" do
          allow_any_instance_of(TagRule).to receive(:destroy).and_return(false)

          spree_delete :destroy, params

          expect(flash[:error]).to eq "There was an issue when removing the Tag rule"
        end
      end
    end
  end

  describe "#edit" do
    let(:enterprise) { create(:distributor_enterprise) }
    let(:params) { { rule_type:, index: 1 } }
    let(:rule_type) { "FilterProducts" }

    before do
      controller_login_as_enterprise_user [enterprise]
    end

    it "returns new tag rule form" do
      spree_get(:new, format:, id: enterprise, params:)

      expect(response).to render_template :new
    end

    context "wiht a wrong tag rule type" do
      let(:rule_type) { "OtherType" }

      it "returns an error" do
        spree_get(:new, format:, id: enterprise, params:)

        expect(response).to render_template :new
        expect(flash[:error]).to eq "Tag rule type not supported"
      end
    end
  end

  describe "#variant_tag_rules", feature: :variant_tag do
    render_views

    let(:enterprise) { create(:distributor_enterprise) }
    let(:q) { "" }
    let!(:rule1) {
      create(:filter_variants_tag_rule, enterprise:, preferred_customer_tags: "Tag-1",
                                        preferred_variant_tags: "variant-tag-1" )
    }
    let!(:rule2) {
      create(:filter_variants_tag_rule, enterprise:, preferred_customer_tags: "Tag-1",
                                        preferred_variant_tags: "variant2-tag-1" )
    }
    let!(:rule3) {
      create(:filter_variants_tag_rule, enterprise:, preferred_customer_tags: "organic",
                                        preferred_variant_tags: "variant-organic" )
    }
    let!(:rule4) {
      create(:filter_variants_tag_rule, enterprise:, preferred_customer_tags: "organic",
                                        preferred_variant_tags: "variant-tag-1" )
    }

    before do
      controller_login_as_enterprise_user [enterprise]
    end

    it "returns a list of tag rules and number of assiciated rules" do
      spree_get(:variant_tag_rules, format: :html, enterprise_id: enterprise.id, q:)

      expect(response).to render_template :variant_tag_rules
      expect(response.body).to include "variant-tag-1 has 2 rules"
      expect(response.body).to include "variant2-tag-1 has 1 rule"
      expect(response.body).to include "variant-organic has 1 rule"
    end

    context "with search string" do
      let(:q) { "org" }

      it "returns a list of tag rules matching the string" do
        spree_get(:variant_tag_rules, format: :html, enterprise_id: enterprise.id, q:)

        expect(response).to render_template :variant_tag_rules
        expect(response.body).not_to include "variant-tag-1 has 2 rules"
        expect(response.body).not_to include "variant2-tag-1 has 1 rule"
        expect(response.body).to include "variant-organic has 1 rule"
      end
    end
  end
end
