# frozen_string_literal: true

require 'spec_helper'

describe Voucher do
  let(:enterprise) { build(:enterprise) }

  describe 'associations' do
    it { is_expected.to belong_to(:enterprise).required }
    it { is_expected.to have_many(:adjustments) }
  end

  describe '#code=' do
    it "removes leading and trailing whitespace" do
      voucher = build(:voucher, code: "\r\n\t new_code \r\n\t")

      expect(voucher.code).to eq("new_code")
    end
  end

  describe 'validations' do
    subject { build(:voucher_flat_rate, code: 'new_code', enterprise: enterprise) }

    it { is_expected.to validate_presence_of(:code) }
    it { is_expected.to validate_uniqueness_of(:code).scoped_to(:enterprise_id) }
    it { is_expected.to validate_presence_of(:amount) }
    it { is_expected.to validate_inclusion_of(:voucher_type).in_array(Voucher::TYPES) }

    context "when voucher_type is flat rate" do
      it { is_expected.to validate_numericality_of(:amount).is_greater_than(0) }
    end

    context "when voucher_type is percentage rate" do
      subject { build(:voucher_percentage, code: 'new_code', enterprise: enterprise) }

      it do
        is_expected.to validate_numericality_of(:amount)
          .is_greater_than(0)
          .is_less_than_or_equal_to(100)
      end
    end
  end

  describe '#compute_amount' do
    subject { create(:voucher_flat_rate, code: 'new_code', enterprise: enterprise, amount: 10) }

    let(:order) { create(:order_with_totals) }

    context 'when order total is more than the voucher' do
      subject { create(:voucher, code: 'new_code', enterprise: enterprise, amount: 5) }

      it 'uses the voucher total' do
        expect(subject.compute_amount(order).to_f).to eq(-5)
      end
    end

    context 'when order total is less than the voucher' do
      subject { create(:voucher, code: 'new_code', enterprise: enterprise, amount: 20) }

      it 'matches the order total' do
        expect(subject.compute_amount(order).to_f).to eq(-10)
      end
    end
  end

  describe '#create_adjustment' do
    subject(:adjustment) { voucher.create_adjustment(voucher.code, order) }

    let(:voucher) do
      create(:voucher_flat_rate, code: 'new_code', enterprise: enterprise, amount: 25)
    end
    let(:order) { create(:order_with_line_items, line_items_count: 3, distributor: enterprise) }

    it 'includes an amount of 0' do
      expect(adjustment.amount.to_f).to eq(0.0)
    end

    it 'has no included_tax' do
      expect(adjustment.included_tax.to_f).to eq(0.0)
    end

    it 'sets the adjustment as open' do
      expect(adjustment.state).to eq("open")
    end
  end
end
