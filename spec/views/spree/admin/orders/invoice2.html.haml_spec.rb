# frozen_string_literal: true

require 'spec_helper'

describe 'spree/admin/orders/invoice2.html.haml' do
  let(:order) { create(:completed_order_with_totals, distributor: shop) }
  let(:shop) { create(:distributor_enterprise) }

  before { assign(:order, order) }

  context 'when the customer_balance feature is disabled' do
    before do
      allow(OpenFoodNetwork::FeatureToggle)
        .to receive(:enabled?).with(:customer_balance, user) { false }
    end

    it_behaves_like 'outstanding balance view rendering'
  end

  context 'when the customer_balance feature is enabled' do
    before do
      allow(OpenFoodNetwork::FeatureToggle)
        .to receive(:enabled?).with(:customer_balance, user) { true }
    end

    it_behaves_like 'new outstanding balance view rendering'
  end
end
