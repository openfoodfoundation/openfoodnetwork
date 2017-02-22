require 'spec_helper'

describe Spree::Admin::OverviewController, type: :controller do
  include AuthenticationWorkflow
  context "loading overview" do
    let(:user) { create_enterprise_user(enterprise_limit: 2) }

    before do
      controller.stub spree_current_user: user
    end

    context "when user owns only one enterprise" do
      let!(:enterprise) { create(:distributor_enterprise, owner: user) }

      context "when the referer is not an admin page" do
        before { @request.env['HTTP_REFERER'] = 'http://test.com/some_other_path' }

        context "and the enterprise has sells='unspecified'" do
          before do
            enterprise.update_attribute(:sells, "unspecified")
          end

          it "redirects to the welcome page for the enterprise" do
            spree_get :index
            response.should redirect_to welcome_admin_enterprise_path(enterprise)
          end
        end

        context "and the enterprise does not have sells='unspecified'" do
          it "renders the single enterprise dashboard" do
            spree_get :index
            response.should render_template "single_enterprise_dashboard"
          end
        end
      end

      context "when the refer is an admin page" do
        before { @request.env['HTTP_REFERER'] = 'http://test.com/admin' }

        it "renders the single enterprise dashboard" do
          spree_get :index
          response.should render_template "single_enterprise_dashboard"
        end
      end
    end

    context "when user owns multiple enterprises" do
      let!(:enterprise1) { create(:distributor_enterprise, owner: user) }
      let!(:enterprise2) { create(:distributor_enterprise, owner: user) }

      context "when the referer is not an admin page" do
        before { @request.env['HTTP_REFERER'] = 'http://test.com/some_other_path' }

        context "and at least one owned enterprise has sells='unspecified'" do
          before do
            enterprise1.update_attribute(:sells, "unspecified")
          end

          it "redirects to the enterprises index" do
            spree_get :index
            response.should redirect_to admin_enterprises_path
          end
        end

        context "and no owned enterprises have sells='unspecified'" do
          it "renders the multiple enterprise dashboard" do
            spree_get :index
            response.should render_template "multi_enterprise_dashboard"
          end
        end
      end

      context "when the refer is an admin page" do
        before { @request.env['HTTP_REFERER'] = 'http://test.com/admin' }

        it "renders the multiple enterprise dashboard" do
          spree_get :index
          response.should render_template "multi_enterprise_dashboard"
        end
      end
    end
  end
end
