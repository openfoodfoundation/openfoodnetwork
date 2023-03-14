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

  describe 'after_save' do
    subject { Voucher.create(code: 'new_code', enterprise: enterprise) }

    it 'adds a FlateRate calculator' do
      expect(subject.calculator.instance_of?(Calculator::FlatRate)).to be(true)
    end

    it 'has a preferred_amount of -10' do
      expect(subject.calculator.preferred_amount.to_f).to eq(-10)
    end
  end
end
