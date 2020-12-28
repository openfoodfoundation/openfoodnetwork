# frozen_string_literal: true

require 'spec_helper'

describe VariantStock do
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
    context 'when the variant is on demand' do
      before do
        variant.stock_items.first.update_attribute(
          :backorderable, true
        )
      end

      it 'returns the total items in stock anyway' do
        expect(variant.on_hand).to eq(variant.stock_items.sum(:count_on_hand))
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
          .to eq(variant.stock_items.sum(:count_on_hand))
      end
    end
  end

  describe '#on_hand=' do
    it 'sets the new level as the stock item\'s count_on_hand' do
      variant.on_hand = 3
      unique_stock_item = variant.stock_items.first
      expect(unique_stock_item.count_on_hand).to eq(3)
    end

    context 'when the variant has no stock item' do
      let(:variant) { build_stubbed(:variant) }

      it 'raises' do
        expect { variant.on_hand = 3 }
          .to raise_error(StandardError)
      end
    end
  end

  describe '#on_demand' do
    context 'when the variant has a stock item' do
      let(:variant) { create(:variant) }

      context 'when the stock item is backorderable' do
        before do
          variant.stock_items.first.update_attribute(
            :backorderable, true
          )
        end

        it 'returns true' do
          expect(variant.on_demand).to be_truthy
        end
      end

      context 'when the stock items is not backorderable' do
        it 'returns false' do
          variant = build_stubbed(
            :variant,
            stock_locations: [build_stubbed(:stock_location)]
          )
          expect(variant.on_demand).to be_falsy
        end
      end
    end

    context 'when the variant has not been saved yet' do
      let(:variant) do
        build_stubbed(
          :variant,
          stock_locations: [
            build_stubbed(:stock_location, backorderable_default: false)
          ]
        )
      end

      it 'has no stock items' do
        expect(variant.stock_items.count).to eq 0
      end

      it 'returns stock location default' do
        expect(variant.on_demand).to be_falsy
      end
    end

    context 'when the variant has been soft-deleted' do
      let(:deleted_variant) { create(:variant).tap(&:destroy) }

      it 'has no stock items' do
        expect(deleted_variant.stock_items.count).to eq 0
      end

      it 'returns stock location default' do
        expect(deleted_variant.on_demand).to be_falsy
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
      let(:variant) { build_stubbed(:variant) }

      it 'raises' do
        expect { variant.on_demand = 3 }.to raise_error(StandardError)
      end
    end
  end

  describe '#can_supply?' do
    context 'when variant on_demand' do
      let(:variant) do
        build_stubbed(
          :variant,
          on_demand: true,
          stock_locations: [build_stubbed(:stock_location)]
        )
      end
      let(:stock_item) { Spree::StockItem.new(backorderable: true) }

      before do
        allow(variant).to receive(:stock_items).and_return([stock_item])
      end

      it "returns true for zero" do
        expect(variant.can_supply?(0)).to eq(true)
      end

      it "returns true for large quantity" do
        expect(variant.can_supply?(100_000)).to eq(true)
      end
    end

    context 'when variant not on_demand' do
      context 'when variant in stock' do
        let(:variant) do
          build_stubbed(
            :variant,
            on_demand: false,
            stock_locations: [build_stubbed(:stock_location)]
          )
        end

        it "returns true for zero" do
          expect(variant.can_supply?(0)).to eq(true)
        end

        it "returns true for number equal to stock level" do
          expect(variant.can_supply?(variant.total_on_hand)).to eq(true)
        end

        it "returns false for number above stock level" do
          expect(variant.can_supply?(variant.total_on_hand + 1)).to eq(false)
        end
      end

      context 'when variant out of stock' do
        before { variant.on_hand = 0 }

        it "returns true for zero" do
          expect(variant.can_supply?(0)).to eq(true)
        end

        it "returns false for one" do
          expect(variant.can_supply?(1)).to eq(false)
        end
      end
    end
  end
end
