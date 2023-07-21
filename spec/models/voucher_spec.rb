# frozen_string_literal: true

require 'spec_helper'

describe Voucher do
  let(:enterprise) { build(:enterprise) }

  describe 'associations' do
    it { is_expected.to belong_to(:enterprise).required }
    it { is_expected.to have_many(:adjustments) }
  end

  context "before validation" do
    it "removes leading and trailing whitespace from the code" do
      voucher = build(:voucher, code: "\r\n\t new_code \r\n\t")
      voucher.valid?

      expect(voucher.code).to eq("new_code")
    end
  end

  describe 'validations' do
    subject { build(:voucher, code: 'new_code', enterprise: enterprise) }

    it { is_expected.to validate_length_of(:code).is_at_most(255) }
    it { is_expected.to validate_presence_of(:code) }
    it { is_expected.to validate_uniqueness_of(:code).scoped_to(:enterprise_id) }
    it { is_expected.to validate_presence_of(:amount) }
    it { is_expected.to validate_numericality_of(:amount).is_greater_than(0) }
    it { is_expected.to allow_value("somethingvalid").for(:code) }

    it "is invalid if the code contains certain forbidden characters e.g. new lines" do
      voucher = subject
      ["\n", "\r"].each do |forbidden_code_character|
        voucher.code = "somethingvalid#{forbidden_code_character}somethingvalid"
        expect(voucher).not_to be_valid
        expect(voucher.errors[:code]).to eq(["is invalid"])
      end
    end
  end

  describe '#compute_amount' do
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

    let(:voucher) { create(:voucher, code: 'new_code', enterprise: enterprise, amount: 25) }
    let(:order) { create(:order_with_line_items, line_items_count: 3, distributor: enterprise) }

    it 'includes the full voucher amount' do
      expect(adjustment.amount.to_f).to eq(-25.0)
    end

    it 'has no included_tax' do
      expect(adjustment.included_tax.to_f).to eq(0.0)
    end

    it 'sets the adjustment as open' do
      expect(adjustment.state).to eq("open")
    end
  end
end
