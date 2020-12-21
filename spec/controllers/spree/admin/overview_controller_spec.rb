# frozen_string_literal: true

require 'spec_helper'

describe Spree::Admin::OverviewController, type: :controller do
  describe "#index" do
    before do
      allow(controller).to receive(:spree_current_user).and_return(user)
    end

    context "when user owns only one enterprise" do
      let(:user) { create(:user) }
      let!(:enterprise) { create(:distributor_enterprise, owner: user) }

      context "when the referer is not an admin page" do
        before do
          @request.env['HTTP_REFERER'] = 'http://test.com/not_admin_path'
        end

        context "and the enterprise has sells='unspecified'" do
          before do
            enterprise.update_attribute(:sells, "unspecified")
          end

          it "redirects to the welcome page for the enterprise" do
            spree_get :index
            expect(response)
              .to redirect_to welcome_admin_enterprise_path(enterprise)
          end
        end

        context "and the enterprise does not have sells='unspecified'" do
          it "renders the single enterprise dashboard" do
            spree_get :index
            expect(response).to render_template :single_enterprise_dashboard
          end
        end
      end

      context "when the refer is an admin page" do
        before { @request.env['HTTP_REFERER'] = 'http://test.com/admin' }

        it "renders the single enterprise dashboard" do
          spree_get :index
          expect(response).to render_template :single_enterprise_dashboard
        end
      end
    end

    context "when user owns multiple enterprises" do
      let(:user) { create(:user) }

      let!(:enterprise1) { create(:distributor_enterprise, owner: user) }
      before { create(:distributor_enterprise, owner: user) }

      context "when the referer is not an admin page" do
        before do
          @request.env['HTTP_REFERER'] = 'http://test.com/not_admin_path'
        end

        context "and at least one owned enterprise has sells='unspecified'" do
          before do
            enterprise1.update_attribute(:sells, "unspecified")
          end

          it "redirects to the enterprises index" do
            spree_get :index
            expect(response).to redirect_to admin_enterprises_path
          end
        end

        context "and no owned enterprises have sells='unspecified'" do
          it "renders the multiple enterprise dashboard" do
            spree_get :index
            expect(response).to render_template :multi_enterprise_dashboard
          end
        end
      end

      context "when the refer is an admin page" do
        before { @request.env['HTTP_REFERER'] = 'http://test.com/admin' }

        it "renders the multiple enterprise dashboard" do
          spree_get :index
          expect(response).to render_template :multi_enterprise_dashboard
        end
      end
    end
  end
end
