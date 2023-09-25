# frozen_string_literal: true

require 'spec_helper'

# This is used to test non implemented methods
module Vouchers
  class TestVoucher < Voucher; end
end

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
  end

  describe '#display_value' do
    subject(:voucher) { Vouchers::TestVoucher.new(code: 'new_code', enterprise: enterprise) }

    it "raises not implemented error" do
      expect{ voucher.display_value }
        .to raise_error(NotImplementedError, 'please use concrete voucher')
    end
  end

  describe '#compute_amount' do
    subject(:voucher) { Vouchers::TestVoucher.new(code: 'new_code', enterprise: enterprise) }

    it "raises not implemented error" do
      expect{ voucher.compute_amount(nil) }
        .to raise_error(NotImplementedError, 'please use concrete voucher')
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

  describe '#rate' do
    subject(:voucher) { Vouchers::TestVoucher.new(code: 'new_code', enterprise: enterprise) }

    it "raises not implemented error" do
      expect{ voucher.rate(nil) }
        .to raise_error(NotImplementedError, 'please use concrete voucher')
    end
  end
end
