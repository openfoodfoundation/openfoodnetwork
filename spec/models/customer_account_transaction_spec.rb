# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CustomerAccountTransaction do
  describe 'validations' do
    subject { build(:customer_account_transaction) }

    it { is_expected.to belong_to(:customer) }
    it { is_expected.to validate_presence_of(:amount) }
    it { is_expected.to validate_presence_of(:currency) }
    it { is_expected.to belong_to(:payment_method) }
    it { is_expected.to belong_to(:payment).optional }
  end

  context "extends LocalizedNumber" do
    subject { build_stubbed(:customer_account_transaction) }
    it_behaves_like "a model using the LocalizedNumber module", [:amount]
  end
end
