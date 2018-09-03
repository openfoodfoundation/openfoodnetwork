require 'spec_helper'

describe OpenFoodNetwork::VariantStock do
  let(:variant) { create(:variant) }

  describe '#after_save' do
    context 'when updating a variant' do
      let(:variant) { create(:variant) }
      let(:stock_item) { variant.stock_items.first }

      before { allow(stock_item).to receive(:save) }

      it 'saves its stock item' do
        variant.save
        expect(stock_item).to have_received(:save)
      end
    end
  end

  describe '#on_hand' do
    context 'when the variant is ordered on demand' do
      before do
        variant.stock_items.first.update_attribute(
          :backorderable, true
        )
      end

      it 'returns infinite' do
        expect(variant.on_hand).to eq(Float::INFINITY)
      end
    end

    context 'when the variant is not ordered on demand' do
      before do
        variant.stock_items.first.update_attribute(
          :backorderable, false
        )
      end

      it 'returns the total items in stock' do
        expect(variant.on_hand)
          .to eq(variant.stock_items.sum(&:count_on_hand))
      end
    end
  end

  describe '#count_on_hand' do
    before { allow(variant).to receive(:total_on_hand) }

    it 'delegates to #total_on_hand' do
      variant.count_on_hand
      expect(variant).to have_received(:total_on_hand)
    end
  end

  describe '#on_hand=' do
    context 'when track_inventory_levels is set' do
      before do
        allow(variant).to receive(:count_on_hand=)
        allow(Spree::Config)
          .to receive(:track_inventory_levels) { true }
      end

      it 'delegates to #count_on_hand=' do
        variant.on_hand = 3
        expect(variant)
          .to have_received(:count_on_hand=).with(3)
      end
    end

    context 'when track_inventory_levels is not set' do
      before do
        allow(Spree::Config)
          .to receive(:track_inventory_levels) { false }
      end

      it 'raises' do
        expect { variant.on_hand = 3 }
          .to raise_error(StandardError)
      end
    end
  end

  describe '#count_on_hand=' do
    context 'when the variant has a stock item' do
      let(:variant) { create(:variant) }

      it 'sets the new level as the stock item\'s count_on_hand' do
        variant.count_on_hand = 3
        unique_stock_item = variant.stock_items.first
        expect(unique_stock_item.count_on_hand).to eq(3)
      end
    end

    context 'when the variant has no stock item' do
      let(:variant) { build(:variant) }

      it 'raises' do
        expect { variant.count_on_hand = 3 }
          .to raise_error(StandardError)
      end
    end
  end

  describe '#on_demand' do
    context 'when the stock items is backorderable' do
      before do
        variant.stock_items.first.update_attribute(
          :backorderable, true
        )
      end

      it 'returns true' do
        expect(variant.on_demand).to be_truthy
      end
    end

    context 'when the stock items is backorderable' do
      before do
        variant.stock_items.first.update_attribute(
          :backorderable, false
        )
      end

      it 'returns false' do
        expect(variant.on_demand).to be_falsy
      end
    end
  end

  describe '#on_demand=' do
    context 'when the variant has a stock item' do
      let(:variant) { create(:variant, on_demand: true) }

      it 'sets the value as the stock item\'s backorderable value' do
        variant.on_demand = false
        stock_item = variant.stock_items.first
        expect(stock_item.backorderable).to eq(false)
      end
    end

    context 'when the variant has no stock item' do
      let(:variant) { build(:variant) }

      it 'raises' do
        expect { variant.on_demand = 3 }.to raise_error(StandardError)
      end
    end
  end
end
