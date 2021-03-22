# frozen_string_literal: true

require 'spec_helper'

describe OrderBalance do
  subject(:order_balance) { described_class.new(order) }
  let(:order) { build(:order) }
  let(:user) { order.user }

  describe '#label' do
    context 'when the customer_balance feature is disabled' do
      before do
        allow(OpenFoodNetwork::FeatureToggle)
          .to receive(:enabled?).with(:customer_balance, user) { false }
      end

      context 'when the balance is postive' do
        before do
          allow(order).to receive(:old_outstanding_balance) { 10 }
        end

        it "returns 'balance due'" do
          expect(order_balance.label).to eq(I18n.t(:balance_due))
        end
      end

      context 'when the balance is negative' do
        before do
          allow(order).to receive(:old_outstanding_balance) { -10 }
        end

        it "returns 'credit owed'" do
          expect(order_balance.label).to eq(I18n.t(:credit_owed))
        end
      end

      context 'when the balance is zero' do
        before do
          allow(order).to receive(:old_outstanding_balance) { 0 }
        end

        it "returns 'balance due'" do
          expect(order_balance.label).to eq(I18n.t(:balance_due))
        end
      end
    end

    context 'when the customer_balance feature is enabled' do
      before do
        allow(OpenFoodNetwork::FeatureToggle)
          .to receive(:enabled?).with(:customer_balance, user) { true }
      end

      context 'when the balance is postive' do
        before do
          allow(order).to receive(:new_outstanding_balance) { 10 }
        end

        it "returns 'balance due'" do
          expect(order_balance.label).to eq(I18n.t(:balance_due))
        end
      end

      context 'when the balance is negative' do
        before do
          allow(order).to receive(:new_outstanding_balance) { -10 }
        end

        it "returns 'credit owed'" do
          expect(order_balance.label).to eq(I18n.t(:credit_owed))
        end
      end

      context 'when the balance is zero' do
        before do
          allow(order).to receive(:new_outstanding_balance) { 0 }
        end

        it "returns 'balance due'" do
          expect(order_balance.label).to eq(I18n.t(:balance_due))
        end
      end
    end
  end

  describe '#amount' do
    context 'when the customer_balance feature is disabled' do
      before do
        allow(order).to receive(:old_outstanding_balance) { 10 }
      end

      before do
        allow(OpenFoodNetwork::FeatureToggle)
          .to receive(:enabled?).with(:customer_balance, user) { false }
      end

      it 'returns the balance wraped in a Money object' do
        expect(order_balance.amount).to eq(Spree::Money.new(10, currency: ENV['currency']))
      end
    end

    context 'when the customer_balance feature is enabled' do
      before do
        allow(order).to receive(:new_outstanding_balance) { 20 }
      end

      before do
        allow(OpenFoodNetwork::FeatureToggle)
          .to receive(:enabled?).with(:customer_balance, user) { true }
      end

      it 'returns the balance wraped in a Money object' do
        expect(order_balance.amount).to eq(Spree::Money.new(20, currency: ENV['currency']))
      end
    end
  end

  describe '#zero?' do
    context 'when the customer_balance feature is disabled' do
      before do
        allow(OpenFoodNetwork::FeatureToggle)
          .to receive(:enabled?).with(:customer_balance, user) { false }
      end

      context 'when the balance is zero' do
        before do
          allow(order).to receive(:old_outstanding_balance) { 0 }
        end

        it 'returns true' do
          expect(order_balance.zero?).to eq(true)
        end
      end

      context 'when the balance is positive' do
        before do
          allow(order).to receive(:old_outstanding_balance) { 10 }
        end

        it 'returns false' do
          expect(order_balance.zero?).to eq(false)
        end
      end

      context 'when the balance is negative' do
        before do
          allow(order).to receive(:old_outstanding_balance) { -10 }
        end

        it 'returns false' do
          expect(order_balance.zero?).to eq(false)
        end
      end
    end

    context 'when the customer_balance feature is enabled' do
      before do
        allow(OpenFoodNetwork::FeatureToggle)
          .to receive(:enabled?).with(:customer_balance, user) { true }
      end

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
  end

  describe '#to_f' do
    context 'when the customer_balance feature is disabled' do
      before do
        allow(OpenFoodNetwork::FeatureToggle)
          .to receive(:enabled?).with(:customer_balance, user) { false }
      end

      it 'calls #outstanding_balance' do
        expect(order).to receive(:old_outstanding_balance)
        order_balance.to_f
      end
    end

    context 'when the customer_balance feature is enabled' do
      before do
        allow(OpenFoodNetwork::FeatureToggle)
          .to receive(:enabled?).with(:customer_balance, user) { true }
      end

      it 'calls #new_outstanding_balance' do
        expect(order).to receive(:new_outstanding_balance)
        order_balance.to_f
      end
    end
  end

  describe '#abs' do
    context 'when the customer_balance feature is disabled' do
      before do
        allow(OpenFoodNetwork::FeatureToggle)
          .to receive(:enabled?).with(:customer_balance, user) { false }
      end

      context 'when the balance is zero' do
        before do
          allow(order).to receive(:old_outstanding_balance) { 0 }
        end

        it 'returns its absolute value' do
          expect(order_balance.abs).to eq(0)
        end
      end

      context 'when the balance is positive' do
        before do
          allow(order).to receive(:old_outstanding_balance) { 10 }
        end

        it 'returns its absolute value' do
          expect(order_balance.abs).to eq(10)
        end
      end

      context 'when the balance is negative' do
        before do
          allow(order).to receive(:old_outstanding_balance) { -10 }
        end

        it 'returns its absolute value' do
          expect(order_balance.abs).to eq(10)
        end
      end
    end

    context 'when the customer_balance feature is enabled' do
      before do
        allow(OpenFoodNetwork::FeatureToggle)
          .to receive(:enabled?).with(:customer_balance, user) { true }
      end

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
  end

  describe '#to_s' do
    context 'when the customer_balance feature is disabled' do
      before do
        allow(OpenFoodNetwork::FeatureToggle)
          .to receive(:enabled?).with(:customer_balance, user) { false }
      end

      before do
        allow(order).to receive(:old_outstanding_balance) { 10 }
      end

      it 'returns the balance as a string' do
        expect(order_balance.to_s).to eq('10')
      end
    end

    context 'when the customer_balance feature is enabled' do
      before do
        allow(OpenFoodNetwork::FeatureToggle)
          .to receive(:enabled?).with(:customer_balance, user) { true }
      end

      before do
        allow(order).to receive(:new_outstanding_balance) { 10 }
      end

      it 'returns the balance as a string' do
        expect(order_balance.to_s).to eq('10')
      end
    end
  end

  describe '#+' do
    let(:other_order_balance) { described_class.new(order) }

    context 'when the customer_balance feature is disabled' do
      before do
        allow(OpenFoodNetwork::FeatureToggle)
          .to receive(:enabled?).with(:customer_balance, user) { false }
      end

      before do
        allow(order).to receive(:old_outstanding_balance) { 10 }
      end

      it 'returns the sum of balances' do
        expect(order_balance + other_order_balance).to eq(20.0)
      end
    end

    context 'when the customer_balance feature is enabled' do
      before do
        allow(OpenFoodNetwork::FeatureToggle)
          .to receive(:enabled?).with(:customer_balance, user) { true }
      end

      before do
        allow(order).to receive(:new_outstanding_balance) { 10 }
      end

      it 'returns the balance as a string' do
        expect(order_balance + other_order_balance).to eq(20.0)
      end
    end
  end
end
