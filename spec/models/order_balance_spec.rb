# frozen_string_literal: true

require 'spec_helper'

describe OrderBalance do
  subject(:order_balance) { described_class.new(order) }
  let(:order) { build(:order) }
  let(:user) { order.user }

  describe '#label' do
    context 'when the balance is positive' do
      before do
        allow(order).to receive(:new_outstanding_balance) { 10 }
      end

      it "returns 'balance due'" do
        expect(order_balance.label).to eq('Balance due')
      end
    end

    context 'when the balance is negative' do
      before do
        allow(order).to receive(:new_outstanding_balance) { -10 }
      end

      it "returns 'credit owed'" do
        expect(order_balance.label).to eq('Credit Owed')
      end
    end

    context 'when the balance is zero' do
      before do
        allow(order).to receive(:new_outstanding_balance) { 0 }
      end

      it "returns 'balance due'" do
        expect(order_balance.label).to eq('Balance due')
      end
    end
  end

  describe '#display_amount' do
    before do
      allow(order).to receive(:new_outstanding_balance) { 20 }
    end

    it 'returns the balance wraped in a Money object' do
      expect(order_balance.display_amount).to eq(Spree::Money.new(20, currency: ENV['currency']))
    end
  end

  describe '#zero?' do
    context 'when the balance is zero' do
      before do
        allow(order).to receive(:new_outstanding_balance) { 0 }
      end

      it 'returns true' do
        expect(order_balance.zero?).to eq(true)
      end
    end

    context 'when the balance is positive' do
      before do
        allow(order).to receive(:new_outstanding_balance) { 10 }
      end

      it 'returns false' do
        expect(order_balance.zero?).to eq(false)
      end
    end

    context 'when the balance is negative' do
      before do
        allow(order).to receive(:new_outstanding_balance) { -10 }
      end

      it 'returns false' do
        expect(order_balance.zero?).to eq(false)
      end
    end
  end

  describe '#amount' do
    before do
      allow(order).to receive(:new_outstanding_balance) { 123 }
    end

    it 'calls #new_outstanding_balance' do
      expect(order).to receive(:new_outstanding_balance)
      expect(order_balance.amount).to eq(123)
    end
  end

  describe '#abs' do
    context 'when the balance is zero' do
      before do
        allow(order).to receive(:new_outstanding_balance) { 0 }
      end

      it 'returns its absolute value' do
        expect(order_balance.abs).to eq(0)
      end
    end

    context 'when the balance is positive' do
      before do
        allow(order).to receive(:new_outstanding_balance) { 10 }
      end

      it 'returns its absolute value' do
        expect(order_balance.abs).to eq(10)
      end
    end

    context 'when the balance is negative' do
      before do
        allow(order).to receive(:new_outstanding_balance) { -10 }
      end

      it 'returns its absolute value' do
        expect(order_balance.abs).to eq(10)
      end
    end
  end

  describe '#to_s' do
    before do
      allow(order).to receive(:new_outstanding_balance) { 10 }
    end

    it 'returns the balance as a string' do
      expect(order_balance.to_s).to eq('10')
    end
  end

  describe '#to_f' do
    before do
      allow(order).to receive(:new_outstanding_balance) { 10 }
    end

    it 'returns the balance as a float' do
      expect(order_balance.to_f).to eq(10.0)
    end
  end

  describe '#to_d' do
    before do
      allow(order).to receive(:new_outstanding_balance) { 10 }
    end

    it 'returns the balance as a decimal' do
      expect(order_balance.to_d).to eq(10.0)
    end
  end

  describe '#+' do
    let(:other_order_balance) { described_class.new(order) }

    before do
      allow(order).to receive(:new_outstanding_balance) { 10 }
    end

    it 'returns the balance as a string' do
      expect(order_balance + other_order_balance).to eq(20.0)
    end
  end

  describe '#< and #>' do
    before do
      allow(order).to receive(:new_outstanding_balance) { 10 }
    end

    it 'correctly returns true or false' do
      expect(order_balance > 5).to eq true
      expect(order_balance > 20).to eq false
      expect(order_balance < 15).to eq true
      expect(order_balance < 5).to eq false
    end
  end
end
