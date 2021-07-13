# frozen_string_literal: true

require 'spec_helper'

describe PaymentsRequiringAction do
  let(:user) { create(:user) }
  let(:order) { create(:order, user: user) }
  subject(:payments_requiring_action) { described_class.new(user) }

  describe '#query' do
    context "payment has a cvv_response_message" do
      let(:payment) do
        create(:payment,
               order: order,
               cvv_response_message: "https://stripe.com/redirect",
               state: "requires_authorization")
      end

      it "finds the payment" do
        expect(payments_requiring_action.query.all).to include(payment)
      end
    end

    context "payment has no cvv_response_message" do
      let(:payment) do
        create(:payment, order: order, cvv_response_message: nil)
      end

      it "does not find the payment" do
        expect(payments_requiring_action.query.all).to_not include(payment)
      end
    end
  end
end
