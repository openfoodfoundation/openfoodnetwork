# frozen_string_literal: true

require 'spec_helper'

describe Vouchers::FlatRate do
  let(:enterprise) { build(:enterprise) }

  describe 'validations' do
    subject { build(:voucher_flat_rate, code: 'new_code', enterprise: enterprise) }

    it { is_expected.to validate_presence_of(:amount) }
    it { is_expected.to validate_numericality_of(:amount).is_greater_than(0) }
  end

  describe '#compute_amount' do
    let(:order) { create(:order_with_totals) }

    context 'when order total is more than the voucher' do
      subject { create(:voucher_flat_rate, code: 'new_code', enterprise: enterprise, amount: 5) }

      it 'uses the voucher total' do
        expect(subject.compute_amount(order).to_f).to eq(-5)
      end
    end

    context 'when order total is less than the voucher' do
      subject { create(:voucher_flat_rate, code: 'new_code', enterprise: enterprise, amount: 20) }

      it 'matches the order total' do
        expect(subject.compute_amount(order).to_f).to eq(-10)
      end
    end
  end
end
