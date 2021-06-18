# frozen_string_literal: true

require 'spec_helper'

describe Admin::ProxyOrdersController, type: :controller do
  include AuthenticationHelper

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
      let(:params) { { format: :json, id: proxy_order.id } }

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

          context "when cancellation succeeds" do
            it 'renders the cancelled proxy_order as json' do
              get :cancel, params: params
              json_response = JSON.parse(response.body)
              expect(json_response['state']).to eq "canceled"
              expect(json_response['id']).to eq proxy_order.id
              expect(proxy_order.reload.canceled_at).to be_within(5.seconds).of Time.zone.now
            end
          end

          context "when cancellation fails" do
            before { order_cycle.update(orders_close_at: 1.day.ago) }

            it "shows an error" do
              get :cancel, params: params
              json_response = JSON.parse(response.body)
              expect(json_response['errors']).to eq ['Could not cancel the order']
            end
          end
        end
      end
    end
  end

  describe 'resume' do
    let!(:user) { create(:user, enterprise_limit: 10) }
    let!(:shop) { create(:distributor_enterprise) }
    let!(:order_cycle) { create(:simple_order_cycle, orders_close_at: 1.day.from_now) }
    let!(:payment_method) { create(:payment_method) }
    let!(:shipping_method) { create(:shipping_method) }
    let!(:subscription) do
      create(:subscription, shipping_method: shipping_method, shop: shop, with_items: true)
    end
    let!(:proxy_order) {
      create(:proxy_order, subscription: subscription, order_cycle: order_cycle)
    }
    let(:order) { proxy_order.initialise_order! }

    before do
      # Processing order to completion
      allow(Spree::OrderMailer).to receive(:cancel_email) { double(:email, deliver_later: true) }
      OrderWorkflow.new(order).complete!
      proxy_order.reload
      proxy_order.cancel
      allow(controller).to receive(:spree_current_user) { user }
    end

    context 'json' do
      let(:params) { { format: :json, id: proxy_order.id } }

      context 'as a regular user' do
        it 'redirects to unauthorized' do
          spree_put :resume, params
          expect(response).to redirect_to unauthorized_path
        end
      end

      context 'as an enterprise user' do
        context "without authorisation" do
          let!(:shop2) { create(:distributor_enterprise) }
          before { shop2.update(owner: user) }

          it 'redirects to unauthorized' do
            spree_put :resume, params
            expect(response).to redirect_to unauthorized_path
          end
        end

        context "with authorisation" do
          before { shop.update(owner: user) }

          context "when resuming succeeds" do
            it 'renders the resumed proxy_order as json' do
              get :resume, params: params
              json_response = JSON.parse(response.body)
              expect(json_response['state']).to eq "resumed"
              expect(json_response['id']).to eq proxy_order.id
              expect(proxy_order.reload.canceled_at).to be nil
            end
          end

          context "when resuming fails" do
            before { order_cycle.update(orders_close_at: 1.day.ago) }

            it "shows an error" do
              get :resume, params: params
              json_response = JSON.parse(response.body)
              expect(json_response['errors']).to eq ['Could not resume the order']
            end
          end
        end
      end
    end
  end
end
