# frozen_string_literal: true

require "spec_helper"

RSpec.describe Spree::PaymentMethod::Check do
  let(:payment_method) { build_stubbed(:payment_method) }

  describe "#can_void?" do
    it "allows voiding a payment that wasn't captured yet" do
      payment = build_stubbed(:payment, payment_method:, state: "pending")

      expect(payment_method.can_void?(payment)).to be true
    end

    it "doesn't offer voiding a canceled payment" do
      payment = build_stubbed(:payment, payment_method:, state: "invalid")

      expect(payment_method.can_void?(payment)).to be false
      expect(payment.actions).not_to include("void")
    end
  end
end
