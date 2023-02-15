# frozen_string_literal: true

require 'spec_helper'

describe Voucher do
  describe 'associations' do
    it { is_expected.to belong_to(:enterprise) }
  end

  describe 'validations' do
    subject { Voucher.new(code: 'new_code', enterprise: enterprise) }

    let(:enterprise) { build(:enterprise) }

    it { is_expected.to validate_presence_of(:code) }
    it { is_expected.to validate_uniqueness_of(:code).scoped_to(:enterprise_id) }
  end
end
