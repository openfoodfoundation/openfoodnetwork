require 'spec_helper'

describe Admin::CustomersController, type: :controller do
  include AuthenticationWorkflow

  describe "index" do
    let(:enterprise) { create(:distributor_enterprise) }
    let(:another_enterprise) { create(:distributor_enterprise) }

    context "html" do
      before do
        allow(controller).to receive(:spree_current_user) { enterprise.owner }
      end

      it "returns an empty @collection" do
        spree_get :index, format: :html
        expect(assigns(:collection)).to eq []
      end
    end

    context "json" do
      let!(:customer) { create(:customer, enterprise: enterprise) }

      context "where I manage the enterprise" do
        before do
          allow(controller).to receive(:spree_current_user) { enterprise.owner }
        end

        context "and enterprise_id is given in params" do
          let(:params) { { format: :json, enterprise_id: enterprise.id } }

          it "scopes @collection to customers of that enterprise" do
            spree_get :index, params
            expect(assigns(:collection)).to eq [customer]
          end

          it "serializes the data" do
            expect(ActiveModel::ArraySerializer).to receive(:new)
            spree_get :index, params
          end
        end

        context "and enterprise_id is not given in params" do
          it "returns an empty collection" do
            spree_get :index, format: :json
            expect(assigns(:collection)).to eq []
          end
        end
      end

      context "and I do not manage the enterprise" do
        before do
          allow(controller).to receive(:spree_current_user) { another_enterprise.owner }
        end

        it "returns an empty collection" do
          spree_get :index, format: :json
          expect(assigns(:collection)).to eq []
        end
      end
    end
  end

  describe "update" do
    let(:enterprise) { create(:distributor_enterprise) }
    let(:another_enterprise) { create(:distributor_enterprise) }

    context "json" do
      let!(:customer) { create(:customer, enterprise: enterprise) }

      context "where I manage the customer's enterprise" do
        render_views

        before do
          allow(controller).to receive(:spree_current_user) { enterprise.owner }
        end

        it "allows me to update the customer" do
          spree_put :update, format: :json, id: customer.id, customer: { email: 'new.email@gmail.com' }
          expect(JSON.parse(response.body)["id"]).to eq customer.id
          expect(assigns(:customer)).to eq customer
          expect(customer.reload.email).to eq 'new.email@gmail.com'
        end
      end

      context "where I don't manage the customer's enterprise" do
        before do
          allow(controller).to receive(:spree_current_user) { another_enterprise.owner }
        end

        it "prevents me from updating the customer" do
          spree_put :update, format: :json, id: customer.id, customer: { email: 'new.email@gmail.com' }
          expect(response).to redirect_to spree.unauthorized_path
          expect(assigns(:customer)).to eq nil
          expect(customer.email).to_not eq 'new.email@gmail.com'
        end
      end
    end
  end

  describe "create" do
    let(:enterprise) { create(:distributor_enterprise) }
    let(:another_enterprise) { create(:distributor_enterprise) }

    def create_customer(enterprise)
      spree_put :create, format: :json, customer: { email: 'new@example.com', enterprise_id: enterprise.id }
    end

    context "json" do
      context "where I manage the customer's enterprise" do
        before do
          allow(controller).to receive(:spree_current_user) { enterprise.owner }
        end

        it "allows me to create the customer" do
          expect { create_customer enterprise }.to change(Customer, :count).by(1)
        end
      end

      context "where I don't manage the customer's enterprise" do
        before do
          allow(controller).to receive(:spree_current_user) { another_enterprise.owner }
        end

        it "prevents me from creating the customer" do
          expect { create_customer enterprise }.to change(Customer, :count).by(0)
        end
      end

      context "where I am the admin user" do
        before do
          allow(controller).to receive(:spree_current_user) { create(:admin_user) }
        end

        it "allows admins to create the customer" do
          expect { create_customer enterprise }.to change(Customer, :count).by(1)
        end
      end
    end
  end

  describe "show" do
    let(:enterprise) { create(:distributor_enterprise) }
    let(:another_enterprise) { create(:distributor_enterprise) }

    context "json" do
      let!(:customer) { create(:customer, enterprise: enterprise) }

      context "where I manage the customer's enterprise" do
        render_views

        before do
          allow(controller).to receive(:spree_current_user) { enterprise.owner }
        end

        it "renders the customer as json" do
          spree_get :show, format: :json, id: customer.id
          expect(JSON.parse(response.body)["id"]).to eq customer.id
        end
      end

      context "where I don't manage the customer's enterprise" do
        before do
          allow(controller).to receive(:spree_current_user) { another_enterprise.owner }
        end

        it "prevents me from updating the customer" do
          spree_get :show, format: :json, id: customer.id
          expect(response).to redirect_to spree.unauthorized_path
        end
      end
    end
  end

  describe '#destroy' do
    let(:enterprise) { create(:distributor_enterprise) }
    let(:customer) { create(:customer, enterprise: enterprise) }

    before do
      allow(controller).to receive(:spree_current_user) { enterprise.owner }
    end

    context 'when rendering json' do
      context 'and the destroy succeeds' do
        it 'invokes before destroy callbacks' do
          allow(controller).to receive(:invoke_callbacks).with(:destroy, :after)

          expect(controller).to receive(:invoke_callbacks).with(:destroy, :before)
          spree_delete :destroy, id: customer, format: :json
        end

        it 'returns a no_content status code' do
          spree_delete :destroy, id: customer, format: :json
          expect(JSON.parse(response.body)['id']).to eq customer.id
        end

        it 'invokes after destroy callbacks' do
          allow(controller).to receive(:invoke_callbacks).with(:destroy, :before)

          expect(controller).to receive(:invoke_callbacks).with(:destroy, :after)
          spree_delete :destroy, id: customer, format: :json
        end
      end

      context 'and the destroy fails' do
        before do
          allow(Customer).to receive(:find).with(customer.id.to_s).and_return(customer)
          allow(customer).to receive(:destroy).and_return(false)
        end

        it 'invokes before destroy callbacks' do
          allow(controller).to receive(:invoke_callbacks).with(:destroy, :fails)

          expect(controller).to receive(:invoke_callbacks).with(:destroy, :before)
          spree_delete :destroy, id: customer, format: :json
        end

        it 'renders the errors' do
          spree_delete :destroy, id: customer, format: :json
          expect(response.body).to match('errors')
        end

        it 'returns conflict HTTP status code' do
          spree_delete :destroy, id: customer, format: :json
          expect(response).to have_http_status(:conflict)
        end

        it 'invokes failure destroy callbacks' do
          allow(controller).to receive(:invoke_callbacks).with(:destroy, :before)

          expect(controller).to receive(:invoke_callbacks).with(:destroy, :fails)
          spree_delete :destroy, id: customer, format: :json
        end
      end
    end

    context 'when rendering html' do
      context 'and the destroy succeeds' do
        it 'invokes before destroy callbacks' do
          allow(controller).to receive(:location_after_destroy) { '/fix_location_after_destroy' }
          allow(controller).to receive(:invoke_callbacks).with(:destroy, :after)

          expect(controller).to receive(:invoke_callbacks).with(:destroy, :before)
          spree_delete :destroy, id: customer, format: :html
        end

        it 'raises due to missing #location_after_destroy' do
          expect {
            spree_delete :destroy, id: customer, format: :html
          }.to raise_error(NameError, /location_after_destroy/)
        end

        it 'invokes after destroy callbacks' do
          allow(controller).to receive(:location_after_destroy) { '/fix_location_after_destroy' }
          allow(controller).to receive(:invoke_callbacks).with(:destroy, :before)

          expect(controller).to receive(:invoke_callbacks).with(:destroy, :after)
          spree_delete :destroy, id: customer, format: :html
        end
      end

      context 'and the destroy fails' do
        before do
          allow(Customer).to receive(:find).with(customer.id.to_s).and_return(customer)
          allow(customer).to receive(:destroy).and_return(false)
        end

        it 'invokes before destroy callbacks' do
          allow(controller).to receive(:location_after_destroy) { '/fix_location_after_destroy' }
          allow(controller).to receive(:invoke_callbacks).with(:destroy, :fails)

          expect(controller).to receive(:invoke_callbacks).with(:destroy, :before)
          spree_delete :destroy, id: customer, format: :html
        end

        it 'raises due to missing #location_after_destroy' do
          expect {
            spree_delete :destroy, id: customer, format: :html
          }.to raise_error(NameError, /location_after_destroy/)
        end

        it 'invokes failure destroy callbacks' do
          allow(controller).to receive(:location_after_destroy) { '/fix_location_after_destroy' }
          allow(controller).to receive(:invoke_callbacks).with(:destroy, :before)

          expect(controller).to receive(:invoke_callbacks).with(:destroy, :fails)
          spree_delete :destroy, id: customer, format: :html
        end
      end
    end

    context 'when rendering js' do
      context 'and the destroy succeeds' do
        it 'invokes before destroy callbacks' do
          allow(controller).to receive(:invoke_callbacks).with(:destroy, :after)

          expect(controller).to receive(:invoke_callbacks).with(:destroy, :before)
          spree_delete :destroy, id: customer, format: :js
        end

        it 'renders the spree/admin/shared/destroy partial' do
          spree_delete :destroy, id: customer, format: :js
          expect(response).to render_template('spree/admin/shared/_destroy')
        end

        it 'invokes after destroy callbacks' do
          allow(controller).to receive(:invoke_callbacks).with(:destroy, :before)

          expect(controller).to receive(:invoke_callbacks).with(:destroy, :after)
          spree_delete :destroy, id: customer, format: :js
        end
      end

      context 'and the destroy fails' do
        before do
          allow(Customer).to receive(:find).with(customer.id.to_s).and_return(customer)
          allow(customer).to receive(:destroy).and_return(false)
        end

        it 'raises due to missing template' do
          expect {
            spree_delete :destroy, id: customer, format: :js
          }.to raise_error(ActionView::MissingTemplate)
        end
      end
    end
  end
end
