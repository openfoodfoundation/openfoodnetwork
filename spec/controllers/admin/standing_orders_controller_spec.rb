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

  describe 'create' do
    let!(:user) { create(:user) }
    let!(:shop) { create(:distributor_enterprise, owner: user) }
    let!(:customer) { create(:customer, enterprise: shop) }
    let!(:order_cycle) { create(:simple_order_cycle, coordinator: shop) }
    let!(:schedule) { create(:schedule, order_cycles: [order_cycle]) }
    let!(:payment_method) { create(:payment_method, distributors: [shop]) }
    let!(:shipping_method) { create(:shipping_method, distributors: [shop]) }
    let(:params) { { format: :json, standing_order: { shop_id: shop.id } } }

    context 'as an non-manager of the specified shop' do
      before do
        allow(controller).to receive(:spree_current_user) { create(:user, enterprises: [create(:enterprise)]) }
      end

      it 'redirects to unauthorized' do
        spree_post :create, params
        expect(response).to redirect_to spree.unauthorized_path
      end
    end

    context 'as a manager of the specified shop' do
      before do
        allow(controller).to receive(:spree_current_user) { user }
      end

      context 'when I submit insufficient params' do
        it 'returns errors' do
          expect{ spree_post :create, params }.to_not change{StandingOrder.count}
          json_response = JSON.parse(response.body)
          expect(json_response['errors'].keys).to include 'schedule', 'customer', 'payment_method', 'shipping_method', 'begins_at'
        end
      end

      context 'when I submit params containing ids of inaccessible objects' do
        # As 'user' I shouldnt be able to associate a standing_order with any of these.
        let(:unmanaged_enterprise) { create(:enterprise) }
        let(:unmanaged_schedule) { create(:schedule, order_cycles: [create(:simple_order_cycle, coordinator: unmanaged_enterprise)]) }
        let(:unmanaged_customer) { create(:customer, enterprise: unmanaged_enterprise) }
        let(:unmanaged_payment_method) { create(:payment_method, distributors: [unmanaged_enterprise]) }
        let(:unmanaged_shipping_method) { create(:shipping_method, distributors: [unmanaged_enterprise]) }

        before do
          params[:standing_order].merge!({
            schedule_id: unmanaged_schedule.id,
            customer_id: unmanaged_customer.id,
            payment_method_id: unmanaged_payment_method.id,
            shipping_method_id: unmanaged_shipping_method.id,
            begins_at: 2.days.ago,
            ends_at: 3.weeks.ago
          })
        end

        it 'returns errors' do
          expect{ spree_post :create, params }.to_not change{StandingOrder.count}
          json_response = JSON.parse(response.body)
          expect(json_response['errors'].keys).to include 'schedule', 'customer', 'payment_method', 'shipping_method', 'ends_at'
        end
      end

      context 'when I submit valid and complete params' do
        before do
          params[:standing_order].merge!({
            schedule_id: schedule.id,
            customer_id: customer.id,
            payment_method_id: payment_method.id,
            shipping_method_id: shipping_method.id,
            begins_at: 2.days.ago,
            ends_at: 3.months.from_now
          })
        end

        it 'creates a standing order' do
          expect{ spree_post :create, params }.to change{StandingOrder.count}.by(1)
          standing_order = StandingOrder.last
          expect(standing_order.schedule).to eq schedule
          expect(standing_order.customer).to eq customer
          expect(standing_order.payment_method).to eq payment_method
          expect(standing_order.shipping_method).to eq shipping_method
        end

        context 'with standing_line_items params' do
          let(:variant) { create(:variant) }
          before { params[:standing_line_items] = [{ quantity: 2, variant_id: variant.id}] }

          context 'where the specified variants are not available from the shop' do
            it 'returns an error' do
              expect{ spree_post :create, params }.to_not change{StandingOrder.count}
              json_response = JSON.parse(response.body)
              expect(json_response['errors']['base']).to eq ["#{variant.product.name} - #{variant.full_name} is not available from the selected schedule"]
            end
          end

          context 'where the specified variants are available from the shop' do
            let!(:exchange) { create(:exchange, order_cycle: order_cycle, incoming: false, receiver: shop, variants: [variant])}

            it 'creates standing line items for the standing order' do
              expect{ spree_post :create, params }.to change{StandingOrder.count}.by(1)
              standing_order = StandingOrder.last
              expect(standing_order.standing_line_items.count).to be 1
              standing_line_item = standing_order.standing_line_items.first
              expect(standing_line_item.quantity).to be 2
              expect(standing_line_item.variant).to eq variant
            end
          end
        end
      end
    end
  end
end
