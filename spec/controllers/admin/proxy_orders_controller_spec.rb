require 'spec_helper'

describe Admin::ProxyOrdersController, type: :controller do
  include AuthenticationWorkflow

  describe 'cancel' do
    let!(:user) { create(:user, enterprise_limit: 10) }
    let!(:shop) { create(:distributor_enterprise) }
    let!(:order_cycle) { create(:simple_order_cycle, orders_close_at: 1.day.from_now) }
    let!(:standing_order) { create(:standing_order_with_items, shop: shop) }
    let!(:proxy_order) { create(:proxy_order, standing_order: standing_order, order_cycle: order_cycle) }

    before do
      allow(controller).to receive(:spree_current_user) { user }
    end

    context 'json' do
      let(:params) { { format: :json, id: proxy_order.id } }

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

          context "when cancellation succeeds" do
            it 'renders the cancelled proxy_order as json' do
              spree_get :cancel, params
              json_response = JSON.parse(response.body)
              expect(json_response['state']).to eq "canceled"
              expect(json_response['id']).to eq proxy_order.id
              expect(proxy_order.reload.canceled_at).to be_within(5.seconds).of Time.now
            end
          end

          context "when cancellation fails" do
            before { order_cycle.update_attributes(orders_close_at: 1.day.ago) }

            it "shows an error" do
              spree_get :cancel, params
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
    let!(:standing_order) { create(:standing_order_with_items, shop: shop) }
    let!(:proxy_order) { create(:proxy_order, standing_order: standing_order, order_cycle: order_cycle) }
    let(:order) { proxy_order.order }

    before do
      # Processing order to completion
      order.update_attribute(:shipping_method_id, shipping_method.id)
      while !order.completed? do break unless order.next! end
      proxy_order.update_attribute(:canceled_at, Time.zone.now)
      order.cancel
      allow(controller).to receive(:spree_current_user) { user }
    end

    context 'json' do
      let(:params) { { format: :json, id: proxy_order.id } }

      context 'as a regular user' do
        it 'redirects to unauthorized' do
          spree_put :resume, params
          expect(response).to redirect_to spree.unauthorized_path
        end
      end

      context 'as an enterprise user' do
        context "without authorisation" do
          let!(:shop2) { create(:distributor_enterprise) }
          before { shop2.update_attributes(owner: user) }

          it 'redirects to unauthorized' do
            spree_put :resume, params
            expect(response).to redirect_to spree.unauthorized_path
          end
        end

        context "with authorisation" do
          before { shop.update_attributes(owner: user) }

          context "when resuming succeeds" do
            it 'renders the resumed proxy_order as json' do
              spree_get :resume, params
              json_response = JSON.parse(response.body)
              expect(json_response['state']).to eq "resumed"
              expect(json_response['id']).to eq proxy_order.id
              expect(proxy_order.reload.canceled_at).to be nil
            end
          end

          context "when resuming fails" do
            before { order_cycle.update_attributes(orders_close_at: 1.day.ago) }

            it "shows an error" do
              spree_get :resume, params
              json_response = JSON.parse(response.body)
              expect(json_response['errors']).to eq ['Could not resume the order']
            end
          end
        end
      end
    end
  end
end
