# frozen_string_literal: true

require 'spec_helper'

describe Admin::TagRulesController, type: :controller do
  describe "destroy" do
    context "json" do
      let(:format) { :json }

      let(:enterprise) { create(:distributor_enterprise) }
      let!(:tag_rule) { create(:filter_order_cycles_tag_rule, enterprise: enterprise) }
      let(:params) { { format: format, id: tag_rule.id } }

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
end
