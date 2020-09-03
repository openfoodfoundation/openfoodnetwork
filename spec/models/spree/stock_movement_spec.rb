# frozen_string_literal: true

require 'spec_helper'

describe Spree::StockMovement do
  let(:stock_location) { create(:stock_location_with_items) }
  let(:stock_item) { stock_location.stock_items.order(:id).first }
  subject { build(:stock_movement, stock_item: stock_item) }

  it 'should belong to a stock item' do
    expect(subject).to respond_to(:stock_item)
  end

  it 'is readonly unless new' do
    subject.save
    expect {
      subject.save
    }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end

  context "when quantity is negative" do
    context "after save" do
      it "should decrement the stock item count on hand" do
        subject.quantity = -1
        subject.save
        stock_item.reload
        expect(stock_item.count_on_hand).to eq 14
      end
    end
  end

  context "when quantity is positive" do
    context "after save" do
      it "should increment the stock item count on hand" do
        subject.quantity = 1
        subject.save
        stock_item.reload
        expect(stock_item.count_on_hand).to eq 16
      end
    end
  end
end
