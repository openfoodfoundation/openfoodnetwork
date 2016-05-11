require 'spec_helper'

describe Admin::BusinessModelConfigurationController, type: :controller do
  let(:user) { create(:user) }
  let(:admin) { create(:admin_user) }

  before do
    Spree::Config.set({
      account_invoices_monthly_fixed: 5,
      account_invoices_monthly_rate: 0.02,
      account_invoices_monthly_cap: 50,
      account_invoices_tax_rate: 0.1,
      shop_trial_length_days: 30,
      minimum_billable_turnover: 0
    })
  end

  describe "edit" do
    context "as an enterprise user" do
      before { allow(controller).to receive(:spree_current_user) { user } }

      it "does not allow access" do
        spree_get :edit
        expect(response).to redirect_to spree.unauthorized_path
      end
    end

    context "as super admin" do
      before { allow(controller).to receive(:spree_current_user) { admin } }

      it "allows access" do
        spree_get :edit
        expect(response).to_not redirect_to spree.unauthorized_path
      end
    end
  end

  describe "update" do
    context "as an enterprise user" do
      before { allow(controller).to receive(:spree_current_user) { user } }

      it "does not allow access" do
        spree_get :update
        expect(response).to redirect_to spree.unauthorized_path
      end
    end

    context "as super admin" do
      before {allow(controller).to receive(:spree_current_user) { admin } }
      let(:params) { { settings: { } } }

      context "when settings are invalid" do
        before do
          params[:settings][:account_invoices_monthly_fixed] = ''
          params[:settings][:account_invoices_monthly_rate] = '2'
          params[:settings][:account_invoices_monthly_cap] = '-1'
          params[:settings][:account_invoices_tax_rate] = '4'
          params[:settings][:shop_trial_length_days] = '-30'
          params[:settings][:minimum_billable_turnover] = '-1'
          spree_get :update, params
        end

        it "does not allow them to be set" do
          expect(response).to render_template :edit
          expect(assigns(:settings).errors.count).to be 7
          expect(Spree::Config.account_invoices_monthly_fixed).to eq 5
          expect(Spree::Config.account_invoices_monthly_rate).to eq 0.02
          expect(Spree::Config.account_invoices_monthly_cap).to eq 50
          expect(Spree::Config.account_invoices_tax_rate).to eq 0.1
          expect(Spree::Config.shop_trial_length_days).to eq 30
          expect(Spree::Config.minimum_billable_turnover).to eq 0
        end
      end

      context "when required settings are valid" do
        before do
          params[:settings][:account_invoices_monthly_fixed] = '10'
          params[:settings][:account_invoices_monthly_rate] = '0.05'
          params[:settings][:account_invoices_monthly_cap] = '30'
          params[:settings][:account_invoices_tax_rate] = '0.15'
          params[:settings][:shop_trial_length_days] = '20'
          params[:settings][:minimum_billable_turnover] = '10'
        end

        it "sets global config to the specified values" do
          spree_get :update, params
          expect(assigns(:settings).errors.count).to be 0
          expect(Spree::Config.account_invoices_monthly_fixed).to eq 10
          expect(Spree::Config.account_invoices_monthly_rate).to eq 0.05
          expect(Spree::Config.account_invoices_monthly_cap).to eq 30
          expect(Spree::Config.account_invoices_tax_rate).to eq 0.15
          expect(Spree::Config.shop_trial_length_days).to eq 20
          expect(Spree::Config.minimum_billable_turnover).to eq 10
        end
      end
    end
  end
end
