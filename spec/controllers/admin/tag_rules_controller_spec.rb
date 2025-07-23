# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::TagRulesController do
  describe "destroy" do
    context "json" do
      let(:format) { :json }

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
      spree_get(:new, format: :turbo_stream, id: enterprise, params:)

      expect(response).to render_template :new
    end

    context "wiht a wrong tag rule type" do
      let(:rule_type) { "OtherType" }

      it "returns an error" do
        spree_get(:new, format: :turbo_stream, id: enterprise,  params:)

        expect(response).to render_template :new
        expect(flash[:error]).to eq "Tag rule type not supported"
      end
    end
  end
end
