require 'spec_helper'

describe Admin::StandingOrderOrdersController, type: :controller do
  include AuthenticationWorkflow

  describe 'cancel' do
    let!(:user) { create(:user, enterprise_limit: 10) }
    let!(:shop) { create(:distributor_enterprise) }
    let!(:order_cycle) { create(:simple_order_cycle, orders_close_at: 1.day.from_now) }
    let!(:order) { create(:order, order_cycle: order_cycle) }
    let!(:standing_order) { create(:standing_order_with_items, shop: shop, orders: [order]) }
    let!(:standing_order_order) { standing_order.standing_order_orders.first }

    before do
      allow(controller).to receive(:spree_current_user) { user }
    end

    context 'json' do
      let(:params) { { format: :json, id: standing_order_order.id } }

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
            it 'renders the cancelled standing_order_order as json' do
              spree_get :cancel, params
              json_response = JSON.parse(response.body)
              expect(json_response['status']).to eq "cancelled"
              expect(json_response['id']).to eq standing_order_order.id
              expect(standing_order_order.reload.cancelled_at).to be_within(5.seconds).of Time.now
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
    let!(:order) { create(:order, shipping_method: create(:shipping_method), order_cycle: order_cycle) }
    let!(:standing_order) { create(:standing_order_with_items, shop: shop, orders: [order]) }
    let!(:standing_order_order) { standing_order.standing_order_orders.first }

    before do
      # Processing order to completion
      while !order.completed? do break unless order.next! end
      standing_order_order.update_attribute(:cancelled_at, Time.zone.now)
      order.cancel
      allow(controller).to receive(:spree_current_user) { user }
    end

    context 'json' do
      let(:params) { { format: :json, id: standing_order_order.id } }

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
            it 'renders the resumed standing_order_order as json' do
              spree_get :resume, params
              json_response = JSON.parse(response.body)
              expect(json_response['status']).to eq "resumed"
              expect(json_response['id']).to eq standing_order_order.id
              expect(standing_order_order.reload.cancelled_at).to be nil
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
