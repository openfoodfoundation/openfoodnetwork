# frozen_string_literal: true

require 'spec_helper'

module Spree
  RSpec.describe StockLocation do
    subject { create(:stock_location_with_items) }
    let(:stock_item) { subject.stock_items.order(:id).first }
    let(:variant) { stock_item.variant }

    it 'creates stock_items for all variants' do
      expect(subject.stock_items.count).to eq Variant.count
    end

    it 'finds a stock_item for a variant' do
      stock_item = subject.stock_item(variant)
      expect(stock_item.count_on_hand).to eq 15
    end

    it 'finds a stock_item for a variant by id' do
      stock_item = subject.stock_item(variant.id)
      expect(stock_item.variant).to eq variant
    end

    it 'returns nil when stock_item is not found for variant' do
      stock_item = subject.stock_item(100)
      expect(stock_item).to be_nil
    end

    it 'finds a count_on_hand for a variant' do
      expect(subject.count_on_hand(variant)).to eq 15
    end
  end
end
