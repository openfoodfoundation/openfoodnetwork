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
    let(:product) { create(:product, enterprise_id: enterprise.id) }
    let!(:variant1) { create(:variant, product:, enterprise:, tag_list: "organic,local") }
    let!(:rule) {
      create(:filter_variants_tag_rule, enterprise:, preferred_customer_tags: "vip",
                                        preferred_variant_tags: "premium")
    }
    let(:q) { "" }

    before do
      controller_login_as_enterprise_user [enterprise]
    end

    it "returns tags from variant tag lists" do
      spree_get(:variant_tag_rules, format: :html, enterprise_id: enterprise.id, q:)

      expect(response).to render_template :variant_tag_rules
      expect(response.body).to include "organic"
      expect(response.body).to include "local"
    end

    it "returns variant tags from FilterVariants tag rules" do
      spree_get(:variant_tag_rules, format: :html, enterprise_id: enterprise.id, q:)

      expect(response.body).to include "premium"
    end

    it "does not return customer tags from tag rules" do
      spree_get(:variant_tag_rules, format: :html, enterprise_id: enterprise.id, q:)

      expect(response.body).not_to include "vip"
    end

    it "does not return tags from non-FilterVariants tag rules" do
      create(:filter_order_cycles_tag_rule, enterprise:, preferred_customer_tags: "wholesale",
                                            preferred_exchange_tags: "oc-tag")

      spree_get(:variant_tag_rules, format: :html, enterprise_id: enterprise.id, q:)

      expect(response.body).not_to include "wholesale"
      expect(response.body).not_to include "oc-tag"
    end

    it "returns tags most recently applied to a variant first" do
      variant2 = create(:variant, product:, enterprise:, tag_list: "newer-tag")
      # Ensure variant1's taggings are older
      ActsAsTaggableOn::Tagging.where(taggable: variant2).update_all(created_at: 1.hour.from_now)

      spree_get(:variant_tag_rules, format: :html, enterprise_id: enterprise.id, q:)

      expect(assigns(:tags).index("newer-tag")).to be < assigns(:tags).index("organic")
    end

    it "does not return tags from another enterprise" do
      other_enterprise = create(:distributor_enterprise)
      other_product = create(:product, enterprise_id: other_enterprise.id)
      create(:variant, product: other_product, enterprise: other_enterprise, tag_list: "other-tag")

      spree_get(:variant_tag_rules, format: :html, enterprise_id: enterprise.id, q:)

      expect(response.body).not_to include "other-tag"
    end

    context "with search string" do
      let(:q) { "org" }

      it "returns only tags matching the search string" do
        spree_get(:variant_tag_rules, format: :html, enterprise_id: enterprise.id, q:)

        expect(response).to render_template :variant_tag_rules
        expect(response.body).to include "organic"
        expect(response.body).not_to include "local"
        expect(response.body).not_to include "vip"
        expect(response.body).not_to include "premium"
      end
    end
  end
end
