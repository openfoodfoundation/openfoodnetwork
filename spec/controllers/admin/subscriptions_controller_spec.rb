# frozen_string_literal: true

require 'spec_helper'

describe Admin::SubscriptionsController, type: :controller do
  include AuthenticationHelper

  describe 'index' do
    let!(:user) { create(:user, enterprise_limit: 10) }
    let!(:shop) { create(:distributor_enterprise, enable_subscriptions: true) }

    before do
      allow(controller).to receive(:spree_current_user) { user }
    end

    context 'html' do
      let(:params) { { format: :html } }

      context 'as a regular user' do
        it 'redirects to unauthorized' do
          get :index, params: params
          expect(response).to redirect_to unauthorized_path
        end
      end

      context 'as an enterprise user' do
        before { shop.update(owner: user) }
        let!(:not_enabled_shop) { create(:distributor_enterprise, owner: user) }

        context "where I manage a shop that is set up for subscriptions" do
          let!(:subscription) { create(:subscription, shop: shop) }

          it 'renders the index page with appropriate data' do
            get :index, params: params
            expect(response).to render_template 'index'
            expect(assigns(:collection)).to eq [] # No collection loaded
            expect(assigns(:shops)).to eq [shop] # Shops are loaded
          end
        end

        context "where I don't manage a shop that is set up for subscriptions" do
          it 'renders the setup_explanation page' do
            get :index, params: params
            expect(response).to render_template 'setup_explanation'
            expect(assigns(:collection)).to eq [] # No collection loaded
            expect(assigns(:shop)).to eq shop # First SO enabled shop is loaded
          end
        end
      end
    end

    context 'json' do
      let(:params) { { format: :json } }
      let!(:subscription) { create(:subscription, shop: shop) }

      context 'as a regular user' do
        it 'redirects to unauthorized' do
          get :index, params: params
          expect(response).to redirect_to unauthorized_path
        end
      end

      context 'as an enterprise user' do
        before { shop.update(owner: user) }
        let!(:shop2) { create(:distributor_enterprise, owner: user) }
        let!(:subscription2) { create(:subscription, shop: shop2) }

        it 'renders the collection as json' do
          get :index, params: params
          json_response = JSON.parse(response.body)
          expect(json_response.count).to be 2
          expect(json_response.map{ |so| so['id'] }).to include subscription.id, subscription2.id
        end

        context "when ransack predicates are submitted" do
          before { params.merge!(q: { shop_id_eq: shop2.id }) }

          it "restricts the list of subscriptions" do
            get :index, params: params
            json_response = JSON.parse(response.body)
            expect(json_response.count).to be 1
            ids = json_response.map{ |so| so['id'] }
            expect(ids).to include subscription2.id
            expect(ids).to_not include subscription.id
          end
        end
      end
    end
  end

  describe 'new' do
    let!(:user) { create(:user) }
    let!(:shop) { create(:distributor_enterprise, owner: user) }

    before do
      allow(controller).to receive(:spree_current_user) { user }
    end

    it 'loads the preloads the necessary data' do
      expect(controller).to receive(:load_form_data)
      get :new, params: { subscription: { shop_id: shop.id } }
      expect(assigns(:subscription)).to be_a_new Subscription
      expect(assigns(:subscription).shop).to eq shop
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
    let(:params) { { format: :json, subscription: { shop_id: shop.id } } }

    context 'as an non-manager of the specified shop' do
      before do
        allow(controller).to receive(:spree_current_user) {
                               create(:user, enterprises: [create(:enterprise)])
                             }
      end

      it 'redirects to unauthorized' do
        spree_post :create, params
        expect(response).to redirect_to unauthorized_path
      end
    end

    context 'as a manager of the specified shop' do
      before do
        allow(controller).to receive(:spree_current_user) { user }
      end

      context 'when I submit insufficient params' do
        it 'returns errors' do
          expect{ spree_post :create, params }.to_not change{ Subscription.count }
          json_response = JSON.parse(response.body)
          expect(json_response['errors'].keys).to include 'schedule', 'customer', 'payment_method',
                                                          'shipping_method', 'begins_at'
        end
      end

      context 'when I submit params containing ids of inaccessible objects' do
        # As 'user' I shouldnt be able to associate a subscription with any of these.
        let(:unmanaged_enterprise) { create(:enterprise) }
        let(:unmanaged_schedule) {
          create(:schedule,
                 order_cycles: [create(:simple_order_cycle, coordinator: unmanaged_enterprise)])
        }
        let(:unmanaged_customer) { create(:customer, enterprise: unmanaged_enterprise) }
        let(:unmanaged_payment_method) {
          create(:payment_method, distributors: [unmanaged_enterprise])
        }
        let(:unmanaged_shipping_method) {
          create(:shipping_method, distributors: [unmanaged_enterprise])
        }

        before do
          params[:subscription].merge!(
            schedule_id: unmanaged_schedule.id,
            customer_id: unmanaged_customer.id,
            payment_method_id: unmanaged_payment_method.id,
            shipping_method_id: unmanaged_shipping_method.id,
            begins_at: 2.days.ago,
            ends_at: 3.weeks.ago
          )
        end

        it 'returns errors' do
          expect{ spree_post :create, params }.to_not change{ Subscription.count }
          json_response = JSON.parse(response.body)
          expect(json_response['errors'].keys).to include 'schedule', 'customer', 'payment_method',
                                                          'shipping_method', 'ends_at'
        end
      end

      context 'when I submit complete params with references to accessible objects' do
        let!(:address) { create(:address) }
        let(:variant) { create(:variant) }

        before do
          params[:subscription].merge!(
            schedule_id: schedule.id,
            customer_id: customer.id,
            payment_method_id: payment_method.id,
            shipping_method_id: shipping_method.id,
            begins_at: 2.days.ago,
            ends_at: 3.months.from_now
          )
          params.merge!(
            bill_address: address.attributes.except('id'),
            ship_address: address.attributes.except('id'),
            subscription_line_items: [{ quantity: 2, variant_id: variant.id }]
          )
        end

        context 'where the specified variants are not available from the shop' do
          it 'returns an error' do
            expect{ spree_post :create, params }.to_not change{ Subscription.count }
            json_response = JSON.parse(response.body)
            expect(json_response['errors']['subscription_line_items'])
              .to eq ["#{variant.product.name} - #{variant.full_name} " \
                      "is not available from the selected schedule"]
          end
        end

        context 'where the specified variants are available from the shop' do
          let!(:exchange) {
            create(:exchange, order_cycle: order_cycle, incoming: false, receiver: shop,
                              variants: [variant])
          }

          it 'creates subscription line items for the subscription' do
            expect{ spree_post :create, params }.to change{ Subscription.count }.by(1)
            subscription = Subscription.last
            expect(subscription.schedule).to eq schedule
            expect(subscription.customer).to eq customer
            expect(subscription.payment_method).to eq payment_method
            expect(subscription.shipping_method).to eq shipping_method
            expect(subscription.bill_address.firstname).to eq address.firstname
            expect(subscription.ship_address.firstname).to eq address.firstname
            expect(subscription.subscription_line_items.count).to be 1
            subscription_line_item = subscription.subscription_line_items.first
            expect(subscription_line_item.quantity).to be 2
            expect(subscription_line_item.variant).to eq variant
          end
        end
      end
    end
  end

  describe 'edit' do
    let!(:user) { create(:user) }
    let!(:shop) { create(:distributor_enterprise, owner: user) }
    let!(:customer1) { create(:customer, enterprise: shop) }
    let!(:order_cycle) { create(:simple_order_cycle, coordinator: shop) }
    let!(:schedule) { create(:schedule, order_cycles: [order_cycle]) }
    let!(:payment_method) { create(:payment_method, distributors: [shop]) }
    let!(:shipping_method) { create(:shipping_method, distributors: [shop]) }
    let!(:subscription) {
      create(:subscription,
             shop: shop,
             customer: customer1,
             schedule: schedule,
             payment_method: payment_method,
             shipping_method: shipping_method)
    }

    before do
      allow(controller).to receive(:spree_current_user) { user }
    end

    it 'loads the preloads the necessary data' do
      expect(controller).to receive(:load_form_data)
      get :edit, params: { id: subscription.id }
      expect(assigns(:subscription)).to eq subscription
    end
  end

  describe 'update' do
    let!(:user) { create(:user) }
    let!(:shop) { create(:distributor_enterprise, owner: user) }
    let!(:customer) { create(:customer, enterprise: shop) }
    let!(:product1) { create(:product, supplier: shop) }
    let!(:variant1) {
      create(:variant, product: product1, unit_value: '100', price: 12.00)
    }
    let!(:enterprise_fee) { create(:enterprise_fee, amount: 1.75) }
    let!(:order_cycle) {
      create(:simple_order_cycle, coordinator: shop, orders_open_at: 2.days.from_now,
                                  orders_close_at: 7.days.from_now)
    }
    let!(:outgoing_exchange) {
      order_cycle.exchanges.create(sender: shop, receiver: shop, variants: [variant1],
                                   enterprise_fees: [enterprise_fee])
    }
    let!(:schedule) { create(:schedule, order_cycles: [order_cycle]) }
    let!(:payment_method) { create(:payment_method, distributors: [shop]) }
    let!(:shipping_method) { create(:shipping_method, distributors: [shop]) }
    let!(:subscription) {
      create(:subscription,
             shop: shop,
             customer: customer,
             schedule: schedule,
             payment_method: payment_method,
             shipping_method: shipping_method,
             subscription_line_items: [create(:subscription_line_item, variant: variant1,
                                                                       quantity: 2)])
    }
    let(:subscription_line_item1) { subscription.subscription_line_items.first }
    let(:params) { { format: :json, id: subscription.id, subscription: {} } }

    context 'as an non-manager of the subscription shop' do
      before do
        allow(controller).to receive(:spree_current_user) {
                               create(:user, enterprises: [create(:enterprise)])
                             }
      end

      it 'redirects to unauthorized' do
        spree_post :update, params
        expect(response).to redirect_to unauthorized_path
      end
    end

    context 'as a manager of the subscription shop' do
      before do
        allow(controller).to receive(:spree_current_user) { user }
      end

      context 'when I submit params containing a new customer or schedule id' do
        let!(:new_customer) { create(:customer, enterprise: shop) }
        let!(:new_schedule) { create(:schedule, order_cycles: [order_cycle]) }

        before do
          params[:subscription].merge!(schedule_id: new_schedule.id, customer_id: new_customer.id)
        end

        it 'does not alter customer_id or schedule_id' do
          spree_post :update, params
          subscription.reload
          expect(subscription.customer).to eq customer
          expect(subscription.schedule).to eq schedule
        end
      end

      context 'when I submit params containing ids of inaccessible objects' do
        # As 'user' I shouldnt be able to associate a subscription with any of these.
        let(:unmanaged_enterprise) { create(:enterprise) }
        let(:unmanaged_payment_method) {
          create(:payment_method, distributors: [unmanaged_enterprise])
        }
        let(:unmanaged_shipping_method) {
          create(:shipping_method, distributors: [unmanaged_enterprise])
        }

        before do
          params[:subscription].merge!(
            payment_method_id: unmanaged_payment_method.id,
            shipping_method_id: unmanaged_shipping_method.id
          )
        end

        it 'returns errors' do
          expect{ spree_post :update, params }.to_not change{ Subscription.count }
          json_response = JSON.parse(response.body)
          expect(json_response['errors'].keys).to include 'payment_method', 'shipping_method'
          subscription.reload
          expect(subscription.payment_method).to eq payment_method
          expect(subscription.shipping_method).to eq shipping_method
        end
      end

      context 'when I submit valid params' do
        let!(:new_payment_method) { create(:payment_method, distributors: [shop]) }
        let!(:new_shipping_method) { create(:shipping_method, distributors: [shop]) }

        before do
          params[:subscription].merge!(
            payment_method_id: new_payment_method.id,
            shipping_method_id: new_shipping_method.id
          )
        end

        it 'updates the subscription' do
          spree_post :update, params
          subscription.reload
          expect(subscription.schedule).to eq schedule
          expect(subscription.customer).to eq customer
          expect(subscription.payment_method).to eq new_payment_method
          expect(subscription.shipping_method).to eq new_shipping_method
        end

        context 'with subscription_line_items params' do
          let!(:product2) { create(:product) }
          let!(:variant2) {
            create(:variant, product: product2, unit_value: '1000', price: 6.00)
          }

          before do
            params[:subscription_line_items] =
              [{ id: subscription_line_item1.id, quantity: 1, variant_id: variant1.id },
               { quantity: 2, variant_id: variant2.id }]
          end

          context 'where the specified variants are not available from the shop' do
            it 'returns an error' do
              expect{ spree_post :update, params }
                .to_not change{ subscription.subscription_line_items.count }
              json_response = JSON.parse(response.body)
              expect(json_response['errors']['subscription_line_items'])
                .to eq ["#{product2.name} - #{variant2.full_name} " \
                        "is not available from the selected schedule"]
            end
          end

          context 'where the specified variants are available from the shop' do
            before { outgoing_exchange.update(variants: [variant1, variant2]) }

            it 'creates subscription line items for the subscription' do
              expect{ spree_post :update, params }.to change{
                                                        subscription.subscription_line_items.count
                                                      }.by(1)
              subscription.reload
              expect(subscription.subscription_line_items.count).to be 2
              subscription_line_item = subscription.subscription_line_items.last
              expect(subscription_line_item.quantity).to be 2
              expect(subscription_line_item.variant).to eq variant2
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
    let!(:subscription) { create(:subscription, shop: shop, with_items: true) }
    let!(:proxy_order) {
      create(:proxy_order, subscription: subscription, order_cycle: order_cycle)
    }

    before do
      allow(controller).to receive(:spree_current_user) { user }
    end

    context 'json' do
      let(:params) { { format: :json, id: subscription.id } }

      context 'as a regular user' do
        it 'redirects to unauthorized' do
          spree_put :cancel, params
          expect(response).to redirect_to unauthorized_path
        end
      end

      context 'as an enterprise user' do
        context "without authorisation" do
          let!(:shop2) { create(:distributor_enterprise) }
          before { shop2.update(owner: user) }

          it 'redirects to unauthorized' do
            spree_put :cancel, params
            expect(response).to redirect_to unauthorized_path
          end
        end

        context "with authorisation" do
          before { shop.update(owner: user) }

          context "when at least one associated order is still 'open'" do
            let(:order_cycle) { subscription.order_cycles.first }
            let(:proxy_order) {
              create(:proxy_order, subscription: subscription, order_cycle: order_cycle)
            }
            let!(:order) { proxy_order.initialise_order! }

            before { break unless order.next! while !order.completed? }

            context "when no 'open_orders' directive has been provided" do
              it "renders an error, asking what to do" do
                spree_put :cancel, params
                expect(response.status).to be 409
                json_response = JSON.parse(response.body)
                expect(json_response['errors']['open_orders'])
                  .to eq 'Some orders for this subscription are currently open. ' \
                         'The customer has already been notified that the order will be placed. ' \
                         'Would you like to cancel these order(s) or keep them?'
              end
            end

            context "when 'keep' has been provided as the 'open_orders' directive" do
              before { params.merge!(open_orders: 'keep') }

              it 'renders the cancelled subscription as json, and does not cancel the open order' do
                spree_put :cancel, params
                json_response = JSON.parse(response.body)
                expect(json_response['canceled_at']).to_not be nil
                expect(json_response['id']).to eq subscription.id
                expect(subscription.reload.canceled_at).to be_within(5.seconds).of Time.zone.now
                expect(order.reload.state).to eq 'complete'
                expect(proxy_order.reload.canceled_at).to be nil
              end
            end

            context "when 'cancel' has been provided as the 'open_orders' directive" do
              let(:mail_mock) { double(:mail) }

              before do
                params[:open_orders] = 'cancel'
                allow(Spree::OrderMailer).to receive(:cancel_email) { mail_mock }
                allow(mail_mock).to receive(:deliver_later)
              end

              it 'renders the cancelled subscription as json, and cancels the open order' do
                spree_put :cancel, params
                json_response = JSON.parse(response.body)
                expect(json_response['canceled_at']).to_not be nil
                expect(json_response['id']).to eq subscription.id
                expect(subscription.reload.canceled_at).to be_within(5.seconds).of Time.zone.now
                expect(order.reload.state).to eq 'canceled'
                expect(proxy_order.reload.canceled_at).to be_within(5.seconds).of Time.zone.now
                expect(mail_mock).to have_received(:deliver_later)
              end
            end
          end

          context "when no associated orders are still 'open'" do
            it 'renders the cancelled subscription as json' do
              spree_put :cancel, params
              json_response = JSON.parse(response.body)
              expect(json_response['canceled_at']).to_not be nil
              expect(json_response['id']).to eq subscription.id
              expect(subscription.reload.canceled_at).to be_within(5.seconds).of Time.zone.now
            end
          end
        end
      end
    end
  end

  describe 'pause' do
    let!(:user) { create(:user, enterprise_limit: 10) }
    let!(:shop) { create(:distributor_enterprise) }
    let!(:subscription) { create(:subscription, shop: shop, with_items: true) }

    before do
      allow(controller).to receive(:spree_current_user) { user }
    end

    context 'json' do
      let(:params) { { format: :json, id: subscription.id } }

      context 'as a regular user' do
        it 'redirects to unauthorized' do
          spree_put :pause, params
          expect(response).to redirect_to unauthorized_path
        end
      end

      context 'as an enterprise user' do
        context "without authorisation" do
          let!(:shop2) { create(:distributor_enterprise) }
          before { shop2.update(owner: user) }

          it 'redirects to unauthorized' do
            spree_put :pause, params
            expect(response).to redirect_to unauthorized_path
          end
        end

        context "with authorisation" do
          before { shop.update(owner: user) }

          context "when at least one associated order is still 'open'" do
            let(:order_cycle) { subscription.order_cycles.first }
            let(:proxy_order) {
              create(:proxy_order, subscription: subscription, order_cycle: order_cycle)
            }
            let!(:order) { proxy_order.initialise_order! }

            before { break unless order.next! while !order.completed? }

            context "when no 'open_orders' directive has been provided" do
              it "renders an error, asking what to do" do
                spree_put :pause, params
                expect(response.status).to be 409
                json_response = JSON.parse(response.body)
                expect(json_response['errors']['open_orders'])
                  .to eq 'Some orders for this subscription are currently open. ' \
                         'The customer has already been notified that the order will be placed. ' \
                         'Would you like to cancel these order(s) or keep them?'
              end
            end

            context "when 'keep' has been provided as the 'open_orders' directive" do
              before { params.merge!(open_orders: 'keep') }

              it 'renders the paused subscription as json, and does not cancel the open order' do
                spree_put :pause, params
                json_response = JSON.parse(response.body)
                expect(json_response['paused_at']).to_not be nil
                expect(json_response['id']).to eq subscription.id
                expect(subscription.reload.paused_at).to be_within(5.seconds).of Time.zone.now
                expect(order.reload.state).to eq 'complete'
                expect(proxy_order.reload.canceled_at).to be nil
              end
            end

            context "when 'cancel' has been provided as the 'open_orders' directive" do
              let(:mail_mock) { double(:mail) }

              before do
                params[:open_orders] = 'cancel'
                allow(Spree::OrderMailer).to receive(:cancel_email) { mail_mock }
                allow(mail_mock).to receive(:deliver_later)
              end

              it 'renders the paused subscription as json, and cancels the open order' do
                spree_put :pause, params
                json_response = JSON.parse(response.body)
                expect(json_response['paused_at']).to_not be nil
                expect(json_response['id']).to eq subscription.id
                expect(subscription.reload.paused_at).to be_within(5.seconds).of Time.zone.now
                expect(order.reload.state).to eq 'canceled'
                expect(proxy_order.reload.canceled_at).to be_within(5.seconds).of Time.zone.now
                expect(mail_mock).to have_received(:deliver_later)
              end
            end
          end

          context "when no associated orders are still 'open'" do
            it 'renders the paused subscription as json' do
              spree_put :pause, params
              json_response = JSON.parse(response.body)
              expect(json_response['paused_at']).to_not be nil
              expect(json_response['id']).to eq subscription.id
              expect(subscription.reload.paused_at).to be_within(5.seconds).of Time.zone.now
            end
          end
        end
      end
    end
  end

  describe 'unpause' do
    let!(:user) { create(:user, enterprise_limit: 10) }
    let!(:shop) { create(:distributor_enterprise) }
    let!(:subscription) {
      create(:subscription, shop: shop, paused_at: Time.zone.now, with_items: true)
    }

    before do
      allow(controller).to receive(:spree_current_user) { user }
    end

    context 'json' do
      let(:params) { { format: :json, id: subscription.id, subscription: {} } }

      context 'as a regular user' do
        it 'redirects to unauthorized' do
          spree_put :unpause, params
          expect(response).to redirect_to unauthorized_path
        end
      end

      context 'as an enterprise user' do
        context "without authorisation" do
          let!(:shop2) { create(:distributor_enterprise) }
          before { shop2.update(owner: user) }

          it 'redirects to unauthorized' do
            spree_put :unpause, params
            expect(response).to redirect_to unauthorized_path
          end
        end

        context "with authorisation" do
          before { shop.update(owner: user) }

          context "when at least one order in an open order cycle is 'complete'" do
            let(:order_cycle) { subscription.order_cycles.first }
            let(:proxy_order) {
              create(:proxy_order, subscription: subscription, order_cycle: order_cycle)
            }
            let!(:order) { proxy_order.initialise_order! }

            before { break unless order.next! while !order.completed? }

            context "when no associated orders are 'canceled'" do
              it 'renders the unpaused subscription as json, leaves the order untouched' do
                spree_put :unpause, params
                json_response = JSON.parse(response.body)
                expect(json_response['paused_at']).to be nil
                expect(json_response['id']).to eq subscription.id
                expect(subscription.reload.paused_at).to be nil
                expect(order.reload.state).to eq 'complete'
                expect(proxy_order.reload.canceled_at).to be nil
              end
            end

            context "when at least one associate orders is 'canceled'" do
              before do
                proxy_order.cancel
              end

              context "when no 'canceled_orders' directive has been provided" do
                it "renders a message, informing the user that canceled order can be resumed" do
                  spree_put :unpause, params
                  expect(response.status).to be 409
                  json_response = JSON.parse(response.body)
                  expect(json_response['errors']['canceled_orders'])
                    .to eq 'Some orders for this subscription can be resumed right now. ' \
                           'You can resume them from the orders dropdown.'
                end
              end

              context "when 'notified' has been provided as the 'canceled_orders' directive" do
                before { params.merge!(canceled_orders: 'notified') }

                it 'renders the unpaused subscription as json, leaves the order untouched' do
                  spree_put :unpause, params
                  json_response = JSON.parse(response.body)
                  expect(json_response['paused_at']).to be nil
                  expect(json_response['id']).to eq subscription.id
                  expect(subscription.reload.paused_at).to be nil
                  expect(order.reload.state).to eq 'canceled'
                  expect(proxy_order.reload.canceled_at).to_not be nil
                end
              end
            end
          end

          context "when no associated orders are 'complete'" do
            it 'renders the unpaused subscription as json' do
              spree_put :unpause, params
              json_response = JSON.parse(response.body)
              expect(json_response['paused_at']).to be nil
              expect(json_response['id']).to eq subscription.id
              expect(subscription.reload.paused_at).to be nil
            end

            context "when there is an open OC and no associated orders exist yet for it " \
                    "(OC was opened when the subscription was paused)" do
              it "creates an associated order" do
                spree_put :unpause, params

                expect(subscription.reload.paused_at).to be nil
                expect(subscription.proxy_orders.size).to be 1
              end
            end
          end
        end
      end
    end
  end

  describe "#load_form_data" do
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
      controller.instance_variable_set(:@subscription, Subscription.new(shop: shop))
    end

    it "assigns data to instance variables" do
      controller.send(:load_form_data)
      expect(assigns(:customers)).to include customer1, customer2
      expect(assigns(:schedules)).to eq [schedule]
      expect(assigns(:order_cycles)).to eq [order_cycle]
      expect(assigns(:payment_methods)).to eq [payment_method]
      expect(assigns(:shipping_methods)).to eq [shipping_method]
    end

    context "when other payment methods exist" do
      let!(:stripe) { create(:stripe_sca_payment_method, distributors: [shop]) }
      let!(:paypal) {
        Spree::Gateway::PayPalExpress.create!(name: "PayPalExpress", distributor_ids: [shop.id])
      }
      let!(:bogus) { create(:bogus_payment_method, distributors: [shop]) }

      it "only loads Stripe and Cash payment methods" do
        controller.send(:load_form_data)
        expect(assigns(:payment_methods)).to include payment_method, stripe
        expect(assigns(:payment_methods)).to_not include paypal, bogus
      end
    end
  end
end
