# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Spree::Orders' do
  describe 'GET /orders/:number for a cancelled and resumed order' do
    let(:user) { create(:user) }
    let(:distributor) { create(:distributor_enterprise, allow_order_changes: true) }
    let(:order_cycle) { create(:simple_order_cycle, distributors: [distributor]) }
    let(:order) do
      create(:completed_order_with_totals,
             line_items_count: 2,
             order_cycle:,
             distributor:,
             user:,
             state: 'resumed')
    end

    before do
      login_as user
    end

    it 'renders it as confirmed and editable, without cart-only controls' do
      get order_path(order)

      aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Order ##{order.number}")
        expect(response.body).to include('Confirmed')
        expect(response.body).to include('id="update-order"')
        expect(response.body).to include('Cancel Order')

        expect(response.body).not_to include('id="empty-cart"')
        expect(response.body).not_to include('Empty cart')
        expect(response.body).not_to include('toggle-bought')
      end
    end
  end

  describe 'PATCH /orders/:number for a cancelled and resumed order' do
    let(:user) { create(:user) }
    let(:distributor) { create(:distributor_enterprise, allow_order_changes: true) }
    let(:order_cycle) { create(:simple_order_cycle, distributors: [distributor]) }
    let(:order) do
      create(:completed_order_with_totals,
             line_items_count: 2,
             order_cycle:,
             distributor:,
             user:,
             state: 'resumed')
    end
    let(:params) {
      { order: { line_items_attributes: {
        "0" => { id: order.line_items.first.id, quantity: 1 },
        "1" => { id: order.line_items.second.id, quantity: 0 }
      } } }
    }

    before { login_as user }

    context 'when one item would remain in the order' do
      it 'removes the item and redirects to the order page' do
        patch order_path(order), params: params

        expect(flash[:error]).to be_nil
        expect(response).to redirect_to order_path(order)
        expect(order.reload.line_items.count).to eq 1
      end
    end

    context 'when no item would remain in the order' do
      before { params[:order][:line_items_attributes]["0"][:quantity] = 0 }

      it 'does not remove items and suggests cancellation' do
        patch order_path(order), params: params

        expect(flash[:error])
          .to eq 'Cannot remove the final item from an order, please cancel the order instead.'
        expect(response).to redirect_to order_path(order)
        expect(order.reload.line_items.count).to eq 2
      end
    end
  end
end
