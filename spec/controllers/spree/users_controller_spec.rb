# frozen_string_literal: true

RSpec.describe Spree::UsersController do
  routes { Spree::Core::Engine.routes }

  include AuthenticationHelper

  describe "#show" do
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

    let(:outstanding_balance_query) { instance_double(OutstandingBalanceQuery) }

    before do
      allow(controller).to receive(:spree_current_user) { u1 }
    end

    it "returns orders placed by the user at normal shops" do
      get :show

      expect(orders).to include d1o1, d1o2
      expect(orders).not_to include d1_order_for_u2, d1o3, d2o1
      expect(shops).to include distributor1

      # Doesn't return orders for irrelevant distributors" do
      expect(orders).not_to include d2o1
      expect(shops).not_to include distributor2

      # Doesn't return other users' orders" do
      expect(orders).not_to include d1_order_for_u2

      # Doesn't return uncompleted orders" do
      expect(orders).not_to include d1o3
    end

    it 'calls OutstandingBalanceQuery' do
      allow(OutstandingBalanceQuery).to receive(:new).and_return(outstanding_balance_query)
      expect(outstanding_balance_query).to receive(:call) { Spree::Order.none }

      spree_get :show
    end
  end

  describe '#load_object' do
    it 'redirects to signup path if user is not found' do
      allow(controller).to receive_messages(spree_current_user: nil)
      put :update, params: { user: { email: 'foobar@example.com' } }
      expect(response).to redirect_to('/login')
    end
  end

  describe '#create' do
    it 'creates a new user' do
      post :create,
           params: { user: { email: 'foobar@example.com', password: 'foobar123',
                             password_confirmation: 'foobar123', locale: 'es' } }
      expect(assigns[:user].new_record?).to be_falsey
    end
  end
end
