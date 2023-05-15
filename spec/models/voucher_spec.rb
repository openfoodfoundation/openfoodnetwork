# frozen_string_literal: true

require 'spec_helper'

describe Voucher do
  let(:enterprise) { build(:enterprise) }

  describe 'associations' do
    it { is_expected.to belong_to(:enterprise) }
    it { is_expected.to have_many(:adjustments) }
  end

  describe 'validations' do
    subject { Voucher.new(code: 'new_code', enterprise: enterprise) }

    it { is_expected.to validate_presence_of(:code) }
    it { is_expected.to validate_uniqueness_of(:code).scoped_to(:enterprise_id) }
  end

  describe '#compute_amount' do
    subject { Voucher.create(code: 'new_code', enterprise: enterprise) }

    let(:order) { create(:order_with_totals) }

    it 'returns -10' do
      expect(subject.compute_amount(order).to_f).to eq(-10)
    end

    context 'when order total is smaller than 10' do
      it 'returns minus the order total' do
        order.total = 6
        order.save!

        expect(subject.compute_amount(order).to_f).to eq(-6)
      end
    end
  end

  describe '#create_adjustment' do
    subject(:adjustment) { voucher.create_adjustment(voucher.code, order) }

    let(:voucher) { Voucher.create(code: 'new_code', enterprise: enterprise) }
    let(:order) { create(:order_with_line_items, line_items_count: 1, distributor: enterprise) }

    it 'includes the full voucher amount' do
      expect(adjustment.amount.to_f).to eq(-10.0)
    end

    it 'has no included_tax' do
      expect(adjustment.included_tax.to_f).to eq(0.0)
    end

    it 'sets the adjustment as open' do
      expect(adjustment.state).to eq("open")
    end
  end
end
