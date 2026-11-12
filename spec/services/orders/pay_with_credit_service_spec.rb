# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Orders::PayWithCreditService do
  subject { described_class.new(order) }

  let(:user) { create(:enterprise_user) }

  # Total is 36.00: items 20.00 + shipping 6.00 + cash payment fee 10.00
  # The cash payment is still in "checkout" state, so the order has a balance due
  let(:order) { create(:completed_order_with_fees) }
  let(:cash_payment) { order.payments.first }
  let(:customer) { order.customer }

  context "when the credit covers the balance due" do
    before { create(:customer_account_transaction, amount: 100.00, customer:) }

    it "pays the order with a completed credit payment" do
      subject.call(user:)

      credit_payment = order.payments.customer_credit.last
      expect(credit_payment.state).to eq("completed")
      expect(credit_payment.amount).to eq(26.00)
      expect(order.reload.payment_state).to eq("paid")
    end

    it "invalidates the cash payment and drops its fee" do
      subject.call(user:)

      expect(cash_payment.reload.state).to eq("invalid")
      expect(order.reload.total).to eq(26.00)
      expect(order.payments.incomplete).to be_empty
    end

    it "debits the customer account and records who did it" do
      subject.call(user:)

      transaction = customer.customer_account_transactions.last
      expect(transaction.amount).to eq(-26.00)
      expect(transaction.created_by).to eq(user)
      expect(customer.credit_balance).to eq(74.00)
    end

    it "returns a successful response" do
      response = subject.call(user:)

      expect(response.success?).to eq(true)
      expect(response.message).to eq("$26.00 of customer credit used to pay this order")
    end
  end

  context "when the credit covers part of the balance due" do
    before { create(:customer_account_transaction, amount: 20.00, customer:) }

    it "pays with all the available credit" do
      subject.call(user:)

      credit_payment = order.payments.customer_credit.last
      expect(credit_payment.state).to eq("completed")
      expect(credit_payment.amount).to eq(20.00)
      expect(customer.credit_balance).to eq(0.00)
    end

    it "replaces the cash payment with one for the remaining amount" do
      subject.call(user:)

      expect(cash_payment.reload.state).to eq("invalid")

      remainder = order.payments.reload.incomplete.sole
      expect(remainder.payment_method).to eq(cash_payment.payment_method)
      expect(remainder.state).to eq("checkout")
      # The cash payment fee still applies to the remaining amount
      expect(order.reload.total).to eq(36.00)
      expect(remainder.amount).to eq(16.00)
      expect(order.payment_state).to eq("balance_due")
      expect(order.new_outstanding_balance).to eq(16.00)
    end
  end

  context "when the order is resumed" do
    before do
      create(:customer_account_transaction, amount: 100.00, customer:)
      order.update_columns(state: "resumed")
    end

    it "pays the order" do
      expect(subject.call(user:).success?).to eq(true)
      expect(order.reload.payment_state).to eq("paid")
    end
  end

  describe "when the order can't be paid with credit" do
    before { create(:customer_account_transaction, amount: 100.00, customer:) }

    shared_examples "no payment with credit" do |message|
      it "returns a failed response and doesn't change the order" do
        expect {
          response = subject.call(user:)

          expect(response.failure?).to eq(true)
          expect(response.message).to eq(message)
        }.not_to change { order.payments.reload.map(&:state) }

        expect(order.payments.customer_credit).to be_empty
      end
    end

    context "without customer" do
      before { order.update_columns(customer_id: nil) }

      it_behaves_like "no payment with credit", "This order has no customer"
    end

    context "when the order is not complete" do
      before { order.update_columns(state: "canceled") }

      it_behaves_like "no payment with credit",
                      "Only complete orders can be paid with credit"
    end

    context "when there is no balance due" do
      before do
        cash_payment.update_columns(state: "completed")
        order.update_order!
      end

      it_behaves_like "no payment with credit", "There is no balance due on this order"
    end

    context "when the customer has no credit" do
      before { create(:customer_account_transaction, amount: -100.00, customer:) }

      it_behaves_like "no payment with credit", "The customer has no credit available"
    end

    context "when a card payment is pending" do
      before do
        stripe = create(:stripe_sca_payment_method, distributors: [order.distributor])
        create(:payment, order:, payment_method: stripe, amount: order.total, state: "pending")
      end

      it_behaves_like "no payment with credit",
                      "This order has a pending StripeSCA payment. " \
                      "Void it before paying with credit."
    end
  end

  context "when the credit payment fails" do
    before do
      create(:customer_account_transaction, amount: 100.00, customer:)
      failed_response = ActiveMerchant::Billing::Response.new(false, "Purchase error")
      allow_any_instance_of(Spree::PaymentMethod::CustomerCredit).to receive(:purchase)
        .and_return(failed_response)
    end

    it "logs the error" do
      expect(Alert).to receive(:raise).with(Spree::Core::GatewayError)
      subject.call(user:)
    end

    it "leaves the order and the customer account unchanged" do
      subject.call(user:)

      expect(order.payments.reload.customer_credit).to be_empty
      expect(cash_payment.reload.state).to eq("checkout")
      expect(order.reload.total).to eq(36.00)
      expect(customer.credit_balance).to eq(100.00)
    end

    it "returns a failed response" do
      response = subject.call(user:)

      expect(response.failure?).to eq(true)
      expect(response.message).to eq("Purchase error")
    end
  end
end
