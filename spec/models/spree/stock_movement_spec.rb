# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Spree::StockMovement do
  let(:stock_item) { create(:variant, on_hand: 15).stock_item }
  subject { build(:stock_movement, stock_item:) }

  it 'should belong to a stock item' do
    expect(subject).to respond_to(:stock_item)
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
