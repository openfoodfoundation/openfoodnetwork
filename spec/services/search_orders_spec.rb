# frozen_string_literal: true

require 'spec_helper'

describe SearchOrders do
  let!(:distributor) { create(:distributor_enterprise) }
  let!(:order1) { create(:order_with_line_items, distributor: distributor, line_items_count: 3) }
  let!(:order2) { create(:order_with_line_items, distributor: distributor, line_items_count: 2) }
  let!(:order3) { create(:order_with_line_items, distributor: distributor, line_items_count: 1) }

  let(:enterprise_user) { distributor.owner }

  describe '#orders' do
    let(:params) { {} }
    let(:service) { SearchOrders.new(params, enterprise_user) }

    it 'returns orders' do
      expect(service.orders.count.length).to eq 3
    end
  end
end
