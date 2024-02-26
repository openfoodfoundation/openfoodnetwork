# frozen_string_literal: true

require 'spec_helper'

describe PaymentsRequiringActionQuery do
  let(:user) { create(:user) }
  let(:order) { create(:order, user:) }
  subject { described_class.new(user).call }

  describe '#call' do
    context "payment has a cvv_response_message" do
      let(:payment) do
        create(:payment,
               order:,
               cvv_response_message: "https://stripe.com/redirect",
               state: "requires_authorization")
      end

      it "finds the payment" do
        expect(subject.all).to include(payment)
      end
    end

    context "payment has no cvv_response_message" do
      let(:payment) do
        create(:payment, order:, cvv_response_message: nil)
      end

      it "does not find the payment" do
        expect(subject.all).to_not include(payment)
      end
    end
  end
end
