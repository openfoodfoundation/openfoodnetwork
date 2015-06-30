require 'spec_helper'

describe Admin::AccountsAndBillingSettingsController, type: :controller do
  let!(:accounts_distributor) { create(:distributor_enterprise) }
  let!(:new_distributor) { create(:distributor_enterprise) }
  let(:user) { create(:user) }
  let(:admin) { create(:admin_user) }

  before do
    Spree::Config.set({
      accounts_distributor_id: accounts_distributor.id,
      collect_billing_information: true,
      create_invoices_for_enterprise_users: false
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

      it "loads relevant global settings into a locally dummy class" do
        spree_get :edit
        settings = assigns(:settings)

        expect(settings.accounts_distributor_id).to eq accounts_distributor.id
        expect(settings.collect_billing_information).to eq true
        expect(settings.create_invoices_for_enterprise_users).to eq false
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

      context "when create_invoices_for_enterprise_users is false" do
        before { params[:settings][:create_invoices_for_enterprise_users] = '0' }

        context "and account_distributor_id and collect_billing_information are not set" do
          before do
            params[:settings][:accounts_distributor_id] = ''
            params[:settings][:collect_billing_information] = '0'
            spree_get :update, params
          end

          it "allows them to be empty/false" do
            expect(Spree::Config.accounts_distributor_id).to eq 0
            expect(Spree::Config.collect_billing_information).to be false
            expect(Spree::Config.create_invoices_for_enterprise_users).to be false
          end
        end

        context "and account_distributor_id and collect_billing_information are set" do
          before do
            params[:settings][:accounts_distributor_id] = new_distributor.id
            params[:settings][:collect_billing_information] = '1'
            spree_get :update, params
          end

          it "sets global config to the specified values" do
            expect(Spree::Config.accounts_distributor_id).to eq new_distributor.id
            expect(Spree::Config.collect_billing_information).to be true
            expect(Spree::Config.create_invoices_for_enterprise_users).to be false
          end
        end
      end

      context "when create_invoices_for_enterprise_users is true" do
        before { params[:settings][:create_invoices_for_enterprise_users] = '1' }

        context "and account_distributor_id and collect_billing_information are not set" do
          before do
            params[:settings][:accounts_distributor_id] = ''
            params[:settings][:collect_billing_information] = '0'
            spree_get :update, params
          end

          it "does not allow them to be empty/false" do
            expect(response).to render_template :edit
            expect(assigns(:settings).errors.count).to be 2
            expect(Spree::Config.accounts_distributor_id).to eq accounts_distributor.id
            expect(Spree::Config.collect_billing_information).to be true
            expect(Spree::Config.create_invoices_for_enterprise_users).to be false
          end
        end

        context "and account_distributor_id and collect_billing_information are set" do
          before do
            params[:settings][:accounts_distributor_id] = new_distributor.id
            params[:settings][:collect_billing_information] = '1'
            spree_get :update, params
          end

          it "sets global config to the specified values" do
            expect(Spree::Config.accounts_distributor_id).to eq new_distributor.id
            expect(Spree::Config.collect_billing_information).to be true
            expect(Spree::Config.create_invoices_for_enterprise_users).to be true
          end
        end
      end
    end
  end
end
