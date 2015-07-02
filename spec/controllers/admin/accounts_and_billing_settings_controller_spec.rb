require 'spec_helper'

describe Admin::AccountsAndBillingSettingsController, type: :controller do
  let!(:pm1) { create(:payment_method) }
  let!(:sm1) { create(:shipping_method) }
  let!(:pm2) { create(:payment_method) }
  let!(:sm2) { create(:shipping_method) }
  let!(:accounts_distributor) { create(:distributor_enterprise, payment_methods: [pm1], shipping_methods: [sm1]) }
  let!(:new_distributor) { create(:distributor_enterprise, payment_methods: [pm2], shipping_methods: [sm2]) }
  let(:user) { create(:user) }
  let(:admin) { create(:admin_user) }

  before do
    Spree::Config.set({
      accounts_distributor_id: accounts_distributor.id,
      default_accounts_payment_method_id: pm1.id,
      default_accounts_shipping_method_id: sm1.id,
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
        expect(settings.default_accounts_payment_method_id).to eq pm1.id
        expect(settings.default_accounts_shipping_method_id).to eq sm1.id
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

        context "and other settings are not set" do
          before do
            params[:settings][:accounts_distributor_id] = ''
            params[:settings][:default_accounts_payment_method_id] = '0'
            params[:settings][:default_accounts_shipping_method_id] = '0'
            params[:settings][:collect_billing_information] = '0'
            spree_get :update, params
          end

          it "allows them to be empty/false" do
            expect(Spree::Config.accounts_distributor_id).to eq 0
            expect(Spree::Config.default_accounts_payment_method_id).to eq 0
            expect(Spree::Config.default_accounts_shipping_method_id).to eq 0
            expect(Spree::Config.collect_billing_information).to be false
            expect(Spree::Config.create_invoices_for_enterprise_users).to be false
          end
        end

        context "and other settings are set" do
          before do
            params[:settings][:accounts_distributor_id] = new_distributor.id
            params[:settings][:default_accounts_payment_method_id] = pm2.id
            params[:settings][:default_accounts_shipping_method_id] = sm2.id
            params[:settings][:collect_billing_information] = '1'
            spree_get :update, params
          end

          it "sets global config to the specified values" do
            expect(Spree::Config.accounts_distributor_id).to eq new_distributor.id
            expect(Spree::Config.default_accounts_payment_method_id).to eq pm2.id
            expect(Spree::Config.default_accounts_shipping_method_id).to eq sm2.id
            expect(Spree::Config.collect_billing_information).to be true
            expect(Spree::Config.create_invoices_for_enterprise_users).to be false
          end
        end
      end

      context "when create_invoices_for_enterprise_users is true" do
        before { params[:settings][:create_invoices_for_enterprise_users] = '1' }

        context "and other settings are not set" do
          before do
            params[:settings][:accounts_distributor_id] = ''
            params[:settings][:default_accounts_payment_method_id] = '0'
            params[:settings][:default_accounts_shipping_method_id] = '0'
            params[:settings][:collect_billing_information] = '0'
            spree_get :update, params
          end

          it "does not allow them to be empty/false" do
            expect(response).to render_template :edit
            expect(assigns(:settings).errors.count).to be 4
            expect(Spree::Config.accounts_distributor_id).to eq accounts_distributor.id
            expect(Spree::Config.default_accounts_payment_method_id).to eq pm1.id
            expect(Spree::Config.default_accounts_shipping_method_id).to eq sm1.id
            expect(Spree::Config.collect_billing_information).to be true
            expect(Spree::Config.create_invoices_for_enterprise_users).to be false
          end
        end

        context "and other settings are set" do
          before do
            params[:settings][:accounts_distributor_id] = new_distributor.id
            params[:settings][:default_accounts_payment_method_id] = pm2.id
            params[:settings][:default_accounts_shipping_method_id] = sm2.id
            params[:settings][:collect_billing_information] = '1'
            spree_get :update, params
          end

          it "sets global config to the specified values" do
            expect(Spree::Config.accounts_distributor_id).to eq new_distributor.id
            expect(Spree::Config.default_accounts_payment_method_id).to eq pm2.id
            expect(Spree::Config.default_accounts_shipping_method_id).to eq sm2.id
            expect(Spree::Config.collect_billing_information).to be true
            expect(Spree::Config.create_invoices_for_enterprise_users).to be true
          end
        end
      end
    end
  end

  describe "show_methods" do
    context "as an enterprise user" do
      before do
        allow(controller).to receive(:spree_current_user) { user }
        spree_get :show_methods, enterprise_id: accounts_distributor.id
      end

      it "does not allow access" do
        expect(response).to redirect_to spree.unauthorized_path
      end
    end

    context "as super admin" do
      before do
        allow(controller).to receive(:spree_current_user) { admin }
        spree_get :show_methods, enterprise_id: accounts_distributor.id
      end

      it "renders the method_settings template" do
        expect(assigns(:payment_methods)).to eq [pm1]
        expect(assigns(:shipping_methods)).to eq [sm1]
        expect(assigns(:enterprise)).to eq accounts_distributor
        expect(response).to render_template :method_settings
      end
    end
  end
end
