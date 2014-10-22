require 'spec_helper'

describe Spree::Admin::OverviewController do
  include AuthenticationWorkflow
  context "loading overview" do
    let(:user) { create_enterprise_user(enterprise_limit: 2) }

    before do
      controller.stub spree_current_user: user
    end

    context "when user own only one enterprise" do
      let!(:enterprise) { create(:distributor_enterprise, owner: user) }

      it "renders the single enterprise dashboard" do
        spree_get :index
        response.should render_template "single_enterprise_dashboard"
      end
    end

    context "when user owns multiple enterprises" do
      let!(:enterprise1) { create(:distributor_enterprise, owner: user) }
      let!(:enterprise2) { create(:distributor_enterprise, owner: user) }

      it "renders the multi enterprise dashboard" do
        spree_get :index
        response.should render_template "multi_enterprise_dashboard"
      end
    end
  end
end