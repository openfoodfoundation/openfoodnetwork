require 'spec_helper'

describe Admin::StandingOrdersController, type: :controller do
  include AuthenticationWorkflow

  describe 'index' do
    let!(:user) { create(:user, enterprise_limit: 10) }
    let!(:shop) { create(:distributor_enterprise, enable_standing_orders: true) }
    let!(:standing_order) { create(:standing_order, shop: shop) }

    before do
      allow(controller).to receive(:spree_current_user) { user }
    end

    context 'html' do
      let(:params) { { format: :html } }

      context 'as a regular user' do
        it 'redirects to unauthorized' do
          spree_get :index, params
          expect(response).to redirect_to spree.unauthorized_path
        end
      end

      context 'as an enterprise user' do
        before { shop.update_attributes(owner: user) }
        let!(:not_enabled_shop) { create(:distributor_enterprise, owner: user) }

        it 'renders the index page with appropriate data' do
          spree_get :index, params
          expect(response).to render_template 'index'
          expect(assigns(:collection)).to eq [] # No collection loaded
          expect(assigns(:shops)).to eq [shop] # Shops are loaded
        end
      end
    end

    context 'json' do
      let(:params) { { format: :json } }

      context 'as a regular user' do
        it 'redirects to unauthorized' do
          spree_get :index, params
          expect(response).to redirect_to spree.unauthorized_path
        end
      end

      context 'as an enterprise user' do
        before { shop.update_attributes(owner: user) }
        let!(:shop2) { create(:distributor_enterprise, owner: user) }
        let!(:standing_order2) { create(:standing_order, shop: shop2) }

        it 'renders the collection as json' do
          spree_get :index, params
          json_response = JSON.parse(response.body)
          expect(json_response.count).to be 2
          expect(json_response.map{ |so| so['id'] }).to include standing_order.id, standing_order2.id
        end

        context "when ransack predicates are submitted" do
          before { params.merge!(q: { shop_id_eq: shop2.id }) }

          it "restricts the list of standing orders" do
            spree_get :index, params
            json_response = JSON.parse(response.body)
            expect(json_response.count).to be 1
            ids = json_response.map{ |so| so['id'] }
            expect(ids).to include standing_order2.id
            expect(ids).to_not include standing_order.id
          end
        end
      end
    end
  end

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
      spree_get :new, standing_order: { shop_id: shop.id }
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
        let!(:address) { create(:address) }
        before do
          params[:standing_order].merge!({
            schedule_id: schedule.id,
            customer_id: customer.id,
            payment_method_id: payment_method.id,
            shipping_method_id: shipping_method.id,
            begins_at: 2.days.ago,
            ends_at: 3.months.from_now
          })
          params.merge!({
            bill_address: address.attributes.except('id'),
            ship_address: address.attributes.except('id')
          })
        end

        it 'creates a standing order' do
          expect{ spree_post :create, params }.to change{StandingOrder.count}.by(1)
          standing_order = StandingOrder.last
          expect(standing_order.schedule).to eq schedule
          expect(standing_order.customer).to eq customer
          expect(standing_order.payment_method).to eq payment_method
          expect(standing_order.shipping_method).to eq shipping_method
          expect(standing_order.bill_address.firstname).to eq address.firstname
          expect(standing_order.ship_address.firstname).to eq address.firstname
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

  describe 'edit' do
    let!(:user) { create(:user) }
    let!(:shop) { create(:distributor_enterprise, owner: user) }
    let!(:customer1) { create(:customer, enterprise: shop) }
    let!(:customer2) { create(:customer, enterprise: shop) }
    let!(:order_cycle) { create(:simple_order_cycle, coordinator: shop) }
    let!(:schedule) { create(:schedule, order_cycles: [order_cycle]) }
    let!(:payment_method) { create(:payment_method, distributors: [shop]) }
    let!(:shipping_method) { create(:shipping_method, distributors: [shop]) }
    let!(:standing_order) { create(:standing_order,
      shop: shop,
      customer: customer1,
      schedule: schedule,
      payment_method: payment_method,
      shipping_method: shipping_method
    ) }

    before do
      allow(controller).to receive(:spree_current_user) { user }
    end

    it 'loads the preloads the necessary data' do
      spree_get :edit, id: standing_order.id
      expect(assigns(:standing_order)).to eq standing_order
      expect(assigns(:customers)).to include customer1, customer2
      expect(assigns(:schedules)).to eq [schedule]
      expect(assigns(:payment_methods)).to eq [payment_method]
      expect(assigns(:shipping_methods)).to eq [shipping_method]
    end
  end

  describe 'update' do
    let!(:user) { create(:user) }
    let!(:shop) { create(:distributor_enterprise, owner: user) }
    let!(:customer) { create(:customer, enterprise: shop) }
    let!(:product1) { create(:product, supplier: shop) }
    let!(:variant1) { create(:variant, product: product1, unit_value: '100', price: 12.00, option_values: []) }
    let!(:enterprise_fee) { create(:enterprise_fee, amount: 1.75) }
    let!(:order_cycle) { create(:simple_order_cycle, coordinator: shop, orders_open_at: 2.days.from_now, orders_close_at: 7.days.from_now) }
    let!(:outgoing_exchange) { order_cycle.exchanges.create(sender: shop, receiver: shop, variants: [variant1], enterprise_fees: [enterprise_fee]) }
    let!(:schedule) { create(:schedule, order_cycles: [order_cycle]) }
    let!(:payment_method) { create(:payment_method, distributors: [shop]) }
    let!(:shipping_method) { create(:shipping_method, distributors: [shop]) }
    let!(:standing_order) { create(:standing_order,
      shop: shop,
      customer: customer,
      schedule: schedule,
      payment_method: payment_method,
      shipping_method: shipping_method,
      standing_line_items: [create(:standing_line_item, variant: variant1, quantity: 2)]
    ) }
    let(:standing_line_item1) { standing_order.standing_line_items.first}
    let(:params) { { format: :json, id: standing_order.id, standing_order: {} } }

    context 'as an non-manager of the standing order shop' do
      before do
        allow(controller).to receive(:spree_current_user) { create(:user, enterprises: [create(:enterprise)]) }
      end

      it 'redirects to unauthorized' do
        spree_post :update, params
        expect(response).to redirect_to spree.unauthorized_path
      end
    end

    context 'as a manager of the standing_order shop' do
      before do
        allow(controller).to receive(:spree_current_user) { user }
      end

      context 'when I submit params containing a new customer or schedule id' do
        let!(:new_customer) { create(:customer, enterprise: shop) }
        let!(:new_schedule) { create(:schedule, order_cycles: [order_cycle]) }

        before do
          params[:standing_order].merge!({ schedule_id: new_schedule.id, customer_id: new_customer.id})
        end

        it 'does not alter customer_id or schedule_id' do
          spree_post :update, params
          standing_order.reload
          expect(standing_order.customer).to eq customer
          expect(standing_order.schedule).to eq schedule
        end
      end

      context 'when I submit params containing ids of inaccessible objects' do
        # As 'user' I shouldnt be able to associate a standing_order with any of these.
        let(:unmanaged_enterprise) { create(:enterprise) }
        let(:unmanaged_payment_method) { create(:payment_method, distributors: [unmanaged_enterprise]) }
        let(:unmanaged_shipping_method) { create(:shipping_method, distributors: [unmanaged_enterprise]) }

        before do
          params[:standing_order].merge!({
            payment_method_id: unmanaged_payment_method.id,
            shipping_method_id: unmanaged_shipping_method.id,
          })
        end

        it 'returns errors' do
          expect{ spree_post :update, params }.to_not change{StandingOrder.count}
          json_response = JSON.parse(response.body)
          expect(json_response['errors'].keys).to include 'payment_method', 'shipping_method'
          standing_order.reload
          expect(standing_order.payment_method).to eq payment_method
          expect(standing_order.shipping_method).to eq shipping_method
        end
      end

      context 'when I submit valid params' do
        let!(:new_payment_method) { create(:payment_method, distributors: [shop]) }
        let!(:new_shipping_method) { create(:shipping_method, distributors: [shop]) }

        before do
          params[:standing_order].merge!({payment_method_id: new_payment_method.id, shipping_method_id: new_shipping_method.id})
        end

        it 'updates the standing order' do
          spree_post :update, params
          standing_order.reload
          expect(standing_order.schedule).to eq schedule
          expect(standing_order.customer).to eq customer
          expect(standing_order.payment_method).to eq new_payment_method
          expect(standing_order.shipping_method).to eq new_shipping_method
        end

        context 'with standing_line_items params' do
          let!(:product2) { create(:product, supplier: shop) }
          let!(:variant2) { create(:variant, product: product2, unit_value: '1000', price: 6.00, option_values: []) }

          before do
            params[:standing_line_items] = [{id: standing_line_item1.id, quantity: 1, variant_id: variant1.id}, { quantity: 2, variant_id: variant2.id}]
          end

          context 'where the specified variants are not available from the shop' do
            it 'returns an error' do
              expect{ spree_post :update, params }.to_not change{standing_order.standing_line_items.count}
              json_response = JSON.parse(response.body)
              expect(json_response['errors']['base']).to eq ["#{product2.name} - #{variant2.full_name} is not available from the selected schedule"]
            end
          end

          context 'where the specified variants are available from the shop' do
            before { outgoing_exchange.update_attributes(variants: [variant1, variant2]) }

            it 'creates standing line items for the standing order' do
              expect{ spree_post :update, params }.to change{standing_order.standing_line_items.count}.by(1)
              standing_order.reload
              expect(standing_order.standing_line_items.count).to be 2
              standing_line_item = standing_order.standing_line_items.last
              expect(standing_line_item.quantity).to be 2
              expect(standing_line_item.variant).to eq variant2
            end
          end
        end
      end
    end
  end

  describe 'cancel' do
    let!(:user) { create(:user, enterprise_limit: 10) }
    let!(:shop) { create(:distributor_enterprise) }
    let!(:order_cycle) { create(:simple_order_cycle, orders_close_at: 1.day.from_now) }
    let!(:standing_order) { create(:standing_order, shop: shop, with_items: true) }
    let!(:proxy_order) { create(:proxy_order, standing_order: standing_order, order_cycle: order_cycle) }

    before do
      allow(controller).to receive(:spree_current_user) { user }
    end

    context 'json' do
      let(:params) { { format: :json, id: standing_order.id } }

      context 'as a regular user' do
        it 'redirects to unauthorized' do
          spree_put :cancel, params
          expect(response).to redirect_to spree.unauthorized_path
        end
      end

      context 'as an enterprise user' do
        context "without authorisation" do
          let!(:shop2) { create(:distributor_enterprise) }
          before { shop2.update_attributes(owner: user) }

          it 'redirects to unauthorized' do
            spree_put :cancel, params
            expect(response).to redirect_to spree.unauthorized_path
          end
        end

        context "with authorisation" do
          before { shop.update_attributes(owner: user) }

          it 'renders the cancelled standing_order as json' do
            spree_put :cancel, params
            json_response = JSON.parse(response.body)
            expect(json_response['canceled_at']).to_not be nil
            expect(json_response['id']).to eq standing_order.id
            expect(standing_order.reload.canceled_at).to be_within(5.seconds).of Time.now
          end
        end
      end
    end
  end

  describe 'pause' do
    let!(:user) { create(:user, enterprise_limit: 10) }
    let!(:shop) { create(:distributor_enterprise) }
    let!(:standing_order) { create(:standing_order, shop: shop, with_items: true) }

    before do
      allow(controller).to receive(:spree_current_user) { user }
    end

    context 'json' do
      let(:params) { { format: :json, id: standing_order.id } }

      context 'as a regular user' do
        it 'redirects to unauthorized' do
          spree_put :pause, params
          expect(response).to redirect_to spree.unauthorized_path
        end
      end

      context 'as an enterprise user' do
        context "without authorisation" do
          let!(:shop2) { create(:distributor_enterprise) }
          before { shop2.update_attributes(owner: user) }

          it 'redirects to unauthorized' do
            spree_put :pause, params
            expect(response).to redirect_to spree.unauthorized_path
          end
        end

        context "with authorisation" do
          before { shop.update_attributes(owner: user) }

          it 'renders the paused standing_order as json' do
            spree_put :pause, params
            json_response = JSON.parse(response.body)
            expect(json_response['paused_at']).to_not be nil
            expect(json_response['id']).to eq standing_order.id
            expect(standing_order.reload.paused_at).to be_within(5.seconds).of Time.now
          end
        end
      end
    end
  end

  describe 'unpause' do
    let!(:user) { create(:user, enterprise_limit: 10) }
    let!(:shop) { create(:distributor_enterprise) }
    let!(:standing_order) { create(:standing_order, shop: shop, paused_at: Time.zone.now, with_items: true) }

    before do
      allow(controller).to receive(:spree_current_user) { user }
    end

    context 'json' do
      let(:params) { { format: :json, id: standing_order.id } }

      context 'as a regular user' do
        it 'redirects to unauthorized' do
          spree_put :unpause, params
          expect(response).to redirect_to spree.unauthorized_path
        end
      end

      context 'as an enterprise user' do
        context "without authorisation" do
          let!(:shop2) { create(:distributor_enterprise) }
          before { shop2.update_attributes(owner: user) }

          it 'redirects to unauthorized' do
            spree_put :unpause, params
            expect(response).to redirect_to spree.unauthorized_path
          end
        end

        context "with authorisation" do
          before { shop.update_attributes(owner: user) }

          it 'renders the paused standing_order as json' do
            spree_put :unpause, params
            json_response = JSON.parse(response.body)
            expect(json_response['paused_at']).to be nil
            expect(json_response['id']).to eq standing_order.id
            expect(standing_order.reload.paused_at).to be nil
          end
        end
      end
    end
  end
end
