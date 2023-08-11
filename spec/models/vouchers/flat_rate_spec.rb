# frozen_string_literal: true

require 'spec_helper'

describe Vouchers::FlatRate do
  describe 'validations' do
    subject { build(:voucher_flat_rate) }

    it { is_expected.to validate_presence_of(:amount) }
    it { is_expected.to validate_numericality_of(:amount).is_greater_than(0) }
  end

  describe '#compute_amount' do
    let(:order) { create(:order_with_totals) }

    before do
      order.update_columns(item_total: 15)
    end

    context 'when order total is more than the voucher' do
      subject { create(:voucher_flat_rate, amount: 5) }

      it 'uses the voucher total' do
        expect(subject.compute_amount(order).to_f).to eq(-5)
      end
    end

    context 'when order total is less than the voucher' do
      subject { create(:voucher_flat_rate, amount: 20) }

      it 'matches the order total' do
        expect(subject.compute_amount(order).to_f).to eq(-15)
      end
    end
  end

  describe "#rate" do
    subject do
      create(:voucher_flat_rate, code: 'new_code', amount: 5)
    end
    let(:order) { create(:order_with_totals) }

    before do
      order.update_columns(item_total: 10)
    end

    it "returns the voucher rate" do
      # rate = -voucher_amount / order.pre_discount_total
      # -5 / 10 = -0.5
      expect(subject.rate(order).to_f).to eq(-0.5)
    end
  end
end
