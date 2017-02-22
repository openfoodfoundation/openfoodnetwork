require 'spec_helper'

describe Spree::UsersController, type: :controller do
  include AuthenticationWorkflow

  describe "show" do
    let!(:u1) { create(:user) }
    let!(:u2) { create(:user) }
    let!(:distributor1) { create(:distributor_enterprise) }
    let!(:distributor2) { create(:distributor_enterprise) }
    let!(:d1o1) { create(:completed_order_with_totals, distributor: distributor1, user_id: u1.id) }
    let!(:d1o2) { create(:completed_order_with_totals, distributor: distributor1, user_id: u1.id) }
    let!(:d1_order_for_u2) { create(:completed_order_with_totals, distributor: distributor1, user_id: u2.id) }
    let!(:d1o3) { create(:order, state: 'cart', distributor: distributor1, user_id: u1.id) }
    let!(:d2o1) { create(:completed_order_with_totals, distributor: distributor2, user_id: u2.id) }
    let!(:accounts_distributor) { create :distributor_enterprise }
    let!(:order_account_invoice) { create(:order, distributor: accounts_distributor, state: 'complete', user: u1) }

    let(:orders) { assigns(:orders) }
    let(:shops) { Enterprise.where(id: orders.pluck(:distributor_id)) }

    before do
      Spree::Config.set(accounts_distributor_id: accounts_distributor.id)
      allow(controller).to receive(:spree_current_user) { u1 }
    end

    it "returns orders placed by the user at normal shops" do
      spree_get :show

      expect(orders).to eq [d1o1, d1o2]
      expect(shops).to include distributor1

      # Doesn't return orders belonging to the accounts distributor" do
      expect(orders).to_not include order_account_invoice
      expect(shops).to_not include accounts_distributor

      # Doesn't return orders for irrelevant distributors" do
      expect(orders).not_to include d2o1
      expect(shops).not_to include distributor2

      # Doesn't return other users' orders" do
      expect(orders).not_to include d1_order_for_u2

      # Doesn't return uncompleted orders" do
      expect(orders).not_to include d1o3
    end
  end
end
