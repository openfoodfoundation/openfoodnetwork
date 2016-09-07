require 'spec_helper'

describe Admin::StandingOrdersController, type: :controller do
  include AuthenticationWorkflow

  describe 'new' do
    let!(:user) { create(:user) }
    let!(:shop) { create(:distributor_enterprise, owner: user) }
    let!(:customer1) { create(:customer, enterprise: shop) }
    let!(:customer2) { create(:customer, enterprise: shop) }
    let!(:order_cycle) { create(:simple_order_cycle, coordinator: shop) }
    let!(:schedule) { create(:schedule, order_cycles: [order_cycle]) }
    let!(:payment_method) { create(:payment_method, distributors: [shop]) }
    let!(:shipping_method) { create(:shipping_method, distributors: [shop]) }

    before do
      allow(controller).to receive(:spree_current_user) { user }
    end

    it 'loads the preloads the necessary data' do
      spree_get :new, shop_id: shop.id
      expect(assigns(:shop)).to eq shop
      expect(assigns(:standing_order)).to be_a_new StandingOrder
      expect(assigns(:standing_order).shop).to eq shop
      expect(assigns(:customers)).to include customer1, customer2
      expect(assigns(:schedules)).to eq [schedule]
      expect(assigns(:payment_methods)).to eq [payment_method]
      expect(assigns(:shipping_methods)).to eq [shipping_method]
    end
  end
end
