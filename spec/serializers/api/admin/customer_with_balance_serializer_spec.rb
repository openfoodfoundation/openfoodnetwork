# frozen_string_literal: true

require 'spec_helper'

describe Api::Admin::CustomerWithBalanceSerializer do
  let(:serialized_customer) { described_class.new(customer) }

  describe '#balance' do
    let(:customer) { double(Customer, balance_value: 1.2) }
    let(:money) { instance_double(Spree::Money, to_s: "$1.20") }

    before do
      allow(Spree::Money).to receive(:new).with(1.2, currency: "AUD") { money }
    end

    it 'returns the balance_value as a money amount' do
      expect(serialized_customer.balance).to eq("$1.20")
    end
  end

  describe '#balance_status' do
    context 'when the balance_value is positive' do
      let(:customer) { double(Customer, balance_value: 1) }

      it 'returns credit_owed' do
        expect(serialized_customer.balance_status).to eq("credit_owed")
      end
    end

    context 'when the balance_value is negative' do
      let(:customer) { double(Customer, balance_value: -1) }

      it 'returns credit_owed' do
        expect(serialized_customer.balance_status).to eq("balance_due")
      end
    end

    context 'when the balance_value is zero' do
      let(:customer) { double(Customer, balance_value: 0) }

      it 'returns credit_owed' do
        expect(serialized_customer.balance_status).to eq("")
      end
    end
  end
end
