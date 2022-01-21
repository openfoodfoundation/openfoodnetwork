# frozen_string_literal: true

require 'spec_helper'

describe Spree::UsersController, type: :controller do
  routes { Spree::Core::Engine.routes }

  include AuthenticationHelper

  describe "show" do
    let!(:u1) { create(:user) }
    let!(:u2) { create(:user) }
    let!(:distributor1) { create(:distributor_enterprise) }
    let!(:distributor2) { create(:distributor_enterprise) }
    let!(:d1o1) { create(:completed_order_with_totals, distributor: distributor1, user_id: u1.id) }
    let!(:d1o2) { create(:completed_order_with_totals, distributor: distributor1, user_id: u1.id) }
    let!(:d1_order_for_u2) {
      create(:completed_order_with_totals, distributor: distributor1, user_id: u2.id)
    }
    let!(:d1o3) { create(:order, state: 'cart', distributor: distributor1, user_id: u1.id) }
    let!(:d2o1) { create(:completed_order_with_totals, distributor: distributor2, user_id: u2.id) }

    let(:orders) { assigns(:orders) }
    let(:shops) { Enterprise.where(id: orders.pluck(:distributor_id)) }

    let(:outstanding_balance) { instance_double(OutstandingBalance) }

    before do
      allow(controller).to receive(:spree_current_user) { u1 }
    end

    it "returns orders placed by the user at normal shops" do
      get :show

      expect(orders).to include d1o1, d1o2
      expect(orders).to_not include d1_order_for_u2, d1o3, d2o1
      expect(shops).to include distributor1

      # Doesn't return orders for irrelevant distributors" do
      expect(orders).not_to include d2o1
      expect(shops).not_to include distributor2

      # Doesn't return other users' orders" do
      expect(orders).not_to include d1_order_for_u2

      # Doesn't return uncompleted orders" do
      expect(orders).not_to include d1o3
    end

    it 'calls OutstandingBalance' do
      allow(OutstandingBalance).to receive(:new).and_return(outstanding_balance)
      expect(outstanding_balance).to receive(:query) { Spree::Order.none }

      spree_get :show
    end
  end

  describe "registered_email" do
    routes { Openfoodnetwork::Application.routes }

    let!(:user) { create(:user) }

    it "returns ok (200) if email corresponds to a registered user" do
      post :registered_email, params: { email: user.email }
      expect(response).to have_http_status(:ok)
    end

    it "returns not_found (404) if email does not correspond to a registered user" do
      post :registered_email, params: { email: 'nonregistereduser@example.com' }
      expect(response).to have_http_status(:not_found)
    end
  end

  context '#load_object' do
    it 'should redirect to signup path if user is not found' do
      allow(controller).to receive_messages(spree_current_user: nil)
      put :update, params: { user: { email: 'foobar@example.com' } }
      expect(response).to redirect_to('/login')
    end
  end

  context '#create' do
    it 'should create a new user' do
      post :create,
           params: { user: { email: 'foobar@example.com', password: 'foobar123',
                             password_confirmation: 'foobar123' } }
      expect(assigns[:user].new_record?).to be_falsey
    end
  end
end
