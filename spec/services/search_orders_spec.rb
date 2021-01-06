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
end
