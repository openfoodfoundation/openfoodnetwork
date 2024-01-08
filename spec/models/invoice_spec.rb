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

  describe "previous_invoice" do
    it "should return the previous invoice" do
      invoice1 = create(:invoice, order:, number: 1, created_at: 3.days.ago)
      invoice2 = create(:invoice, order:, number: 2, created_at: 2.days.ago)
      invoice3 = create(:invoice, order:, number: 3, created_at: 1.day.ago)
      expect(invoice3.previous_invoice).to eq(invoice2)
      expect(invoice2.previous_invoice).to eq(invoice1)
    end

    it "should return nil if there is no previous invoice" do
      invoice = create(:invoice, order:)
      expect(invoice.previous_invoice).to be_nil
    end
  end
end
