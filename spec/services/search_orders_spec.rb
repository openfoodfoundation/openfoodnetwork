# frozen_string_literal: true

require 'spec_helper'

describe SearchOrders do
  let!(:distributor) { create(:distributor_enterprise) }
  let!(:order1) { create(:order_with_line_items, distributor: distributor, line_items_count: 3) }
  let!(:order2) { create(:order_with_line_items, distributor: distributor, line_items_count: 2) }
  let!(:order3) { create(:order_with_line_items, distributor: distributor, line_items_count: 1) }
  let!(:order_empty) { create(:order, distributor: distributor) }
  let!(:order_empty_but_complete) { create(:order, distributor: distributor, state: :complete) }
  let!(:order_empty_but_canceled) { create(:order, distributor: distributor, state: :canceled) }

  let(:enterprise_user) { distributor.owner }

  describe '#orders' do
    let(:params) { {} }
    let(:service) { SearchOrders.new(params, enterprise_user) }

    it 'returns orders' do
      expect(service.orders.count).to eq 5
      service.orders.each do |order|
        expect(order.id).not_to eq(order_empty.id)
      end
    end
  end
end
