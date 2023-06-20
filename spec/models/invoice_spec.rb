# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Invoice, type: :model do
  let(:distributor) { create(:distributor_enterprise) }
  let(:order) { create(:order, :with_line_item, :completed, distributor:) }
  describe 'presenter' do
    it 'should return an instance of Invoice::DataPresenter' do
      invoice = create(:invoice, order:)
      expect(invoice.presenter).to be_a(Invoice::DataPresenter)
    end
  end

  describe 'serialize_order' do
    it 'serializes the order' do
      invoice = create(:invoice, order:)
      expect(invoice.data).to eq(Invoice::OrderSerializer.new(order).serializable_hash)
    end
  end
end
