# frozen_string_literal: true

require 'spec_helper'

describe SearchOrders do
  let!(:distributor) { create(:distributor_enterprise) }
  let!(:order1) { create(:order, distributor: distributor) }
  let!(:order2) { create(:order, distributor: distributor) }
  let!(:order3) { create(:order, distributor: distributor) }

  let(:enterprise_user) { distributor.owner }

  describe '#orders' do
    let(:params) { {} }
    let(:service) { SearchOrders.new(params, enterprise_user) }

    it 'returns orders' do
      expect(service.orders.count).to eq 3
    end
  end

  describe '#pagination_data' do
    let(:params) { { per_page: 15, page: 1 } }
    let(:service) { SearchOrders.new(params, enterprise_user) }

    it 'returns pagination data' do
      pagination_data = {
        results: 3,
        pages: 1,
        page: 1,
        per_page: 15
      }

      expect(service.pagination_data).to eq pagination_data
    end
  end
end
