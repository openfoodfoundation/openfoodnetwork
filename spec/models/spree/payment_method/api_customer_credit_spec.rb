# frozen_string_literal: true

require "spec_helper"

RSpec.describe Spree::PaymentMethod::ApiCustomerCredit do
  subject { build(:api_customer_credit_payment_method) }

  describe "#name" do
    it { expect(subject.name).to eq("api_payment_method.name") }
  end

  describe "#description" do
    it { expect(subject.description).to eq("api_payment_method.description") }
  end
end
