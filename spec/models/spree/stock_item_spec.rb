# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Spree::StockItem do
  let(:stock_location) { create(:stock_location_with_items) }

  subject { stock_location.stock_items.order(:id).first }

  describe "validation" do
    let(:stock_item) { stock_location.stock_items.first }

    it "requires count_on_hand to be positive if not backorderable" do
      stock_item.backorderable = false

      stock_item.__send__(:count_on_hand=, 1)
      expect(stock_item.valid?).to eq(true)

      stock_item.__send__(:count_on_hand=, 0)
      expect(stock_item.valid?).to eq(true)

      stock_item.__send__(:count_on_hand=, -1)
      expect(stock_item.valid?).to eq(false)
    end

    it "allows count_on_hand to be negative if backorderable" do
      stock_item.backorderable = true

      stock_item.__send__(:count_on_hand=, 1)
      expect(stock_item.valid?).to eq(true)

      stock_item.__send__(:count_on_hand=, -1)
      expect(stock_item.valid?).to eq(true)
    end
  end

  it 'maintains the count on hand for a variant' do
    expect(subject.count_on_hand).to eq 15
  end

  it "can return the stock item's variant's name" do
    expect(subject.variant_name).to eq(subject.variant.name)
  end

  context "available to be included in shipment" do
    context "has stock" do
      it { expect(subject).to be_available }
    end

    context "backorderable" do
      before { subject.backorderable = true }
      it { expect(subject).to be_available }
    end

    context "no stock and not backorderable" do
      before do
        subject.backorderable = false
        allow(subject).to receive_messages(count_on_hand: 0)
      end

      it { expect(subject).not_to be_available }
    end
  end

  context "adjust count_on_hand" do
    let!(:current_on_hand) { subject.count_on_hand }

    it 'is updated pessimistically' do
      copy = Spree::StockItem.find(subject.id)

      subject.adjust_count_on_hand(5)
      expect(subject.count_on_hand).to eq(current_on_hand + 5)

      expect(copy.count_on_hand).to eq(current_on_hand)
      copy.adjust_count_on_hand(5)
      expect(copy.count_on_hand).to eq(current_on_hand + 10)
    end

    context "item out of stock (by two items)" do
      let(:inventory_unit) { double('InventoryUnit') }
      let(:inventory_unit_2) { double('InventoryUnit2') }

      before do
        allow(subject).to receive(:backorderable?).and_return(true)
        subject.adjust_count_on_hand(- (current_on_hand + 2))
      end

      it "doesn't process backorders" do
        expect(subject).not_to receive(:backordered_inventory_units)
        subject.adjust_count_on_hand(1)
      end

      context "adds new items" do
        before {
          allow(subject).to receive_messages(backordered_inventory_units: [inventory_unit,
                                                                           inventory_unit_2])
        }

        it "fills existing backorders" do
          expect(inventory_unit).to receive(:fill_backorder)
          expect(inventory_unit_2).to receive(:fill_backorder)

          subject.adjust_count_on_hand(3)
          expect(subject.count_on_hand).to eq(1)
        end
      end
    end

    context "with stock movements" do
      before { Spree::StockMovement.create(stock_item: subject, quantity: 1) }

      it "doesnt raise ReadOnlyRecord error" do
        expect { subject.destroy }.not_to raise_error
      end
    end
  end
end
