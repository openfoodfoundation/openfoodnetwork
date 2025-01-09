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

    it 'finds determines if you a variant is backorderable' do
      expect(subject.backorderable?(variant)).to eq false
    end

    context 'fill_status' do
      before { variant.on_demand = false }

      it 'is all on_hand if variant is on_demand' do
        variant.on_demand = true

        on_hand, backordered = subject.fill_status(variant, 25)
        expect(on_hand).to eq 25
        expect(backordered).to eq 0
      end

      it 'is all on_hand if on_hand is enough' do
        on_hand, backordered = subject.fill_status(variant, 5)
        expect(on_hand).to eq 5
        expect(backordered).to eq 0
      end

      it 'is some on_hand if not all available' do
        on_hand, backordered = subject.fill_status(variant, 20)
        expect(on_hand).to eq 15
        expect(backordered).to eq 0
      end

      it 'is zero on_hand if none available' do
        variant.on_hand = 0

        on_hand, backordered = subject.fill_status(variant, 20)
        expect(on_hand).to eq 0
        expect(backordered).to eq 0
      end
    end
  end
end
