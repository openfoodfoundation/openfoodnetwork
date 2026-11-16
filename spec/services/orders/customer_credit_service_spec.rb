# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Orders::CustomerCreditService do
  subject { described_class.new(order) }

  let(:distributor) { create(:distributor_enterprise) }
  let(:order_cycle) { create(:order_cycle, distributors: [distributor]) }
  let(:credit_payment_method) { Spree::PaymentMethod.customer_credit }
  let(:user) { create(:enterprise_user) }

  describe "#apply" do
    let(:order) {
      create(:order_with_line_items, line_items_count: 1, distributor:, order_cycle:,
                                     customer: create(:customer, enterprise: distributor))
    }
    it "adds a customer credit payment to the order" do
      # Add credit
      create(
        :customer_account_transaction,
        amount: 100.00,
        customer: order.customer
      )
      subject.apply

      credit_payment = order.payments.find_by(payment_method: credit_payment_method)
      expect(credit_payment).to be_present
      expect(credit_payment.amount).to eq(10.00) # order.total is 10.00
      expect(credit_payment.state).to eq("checkout")
    end

    context "when no credit available" do
      it "doesn't add a customer credit payment" do
        subject.apply

        expect(order.payments.where(payment_method: credit_payment_method)).to be_empty
      end
    end

    context "when credit payment already added" do
      before do
        create(
          :customer_account_transaction,
          amount: 100.00,
          customer: order.customer,
        )
      end

      it "doesn't add more credit payment" do
        subject.apply

        credit_payment = order.payments.find_by(payment_method: credit_payment_method)
        expect(credit_payment.amount).to eq(10.00)

        subject.apply

        credit_payments = order.payments.customer_credit
        expect(credit_payments.count).to eq(1)
        expect(credit_payments.first.amount).to eq(10.00)
      end

      context "when order total changed" do
        it "update the credit amount" do
          subject.apply

          credit_payment = order.payments.find_by(payment_method: credit_payment_method)
          expect(credit_payment.amount).to eq(10.00)

          order.update!(total: 15.00)

          subject.apply

          credit_payments = order.payments.customer_credit
          expect(credit_payments.count).to eq(1)
          expect(credit_payments.first.amount).to eq(15.00)
        end
      end
    end

    context "when not enought credit available" do
      it "adds credit payment using all credit" do
        # Add credit
        create(
          :customer_account_transaction,
          amount: 5.00,
          customer: order.customer,
        )
        subject.apply

        credit_payment = order.payments.find_by(payment_method: credit_payment_method)
        expect(credit_payment.amount).to eq(5.00)
      end
    end

    context "when part of the order is already paid" do
      before do
        create(:customer_account_transaction, amount: 100.00, customer: order.customer)
        order.update_columns(payment_total: 4.00)
      end

      it "only uses credit for what is left to pay" do
        subject.apply

        credit_payment = order.payments.find_by(payment_method: credit_payment_method)
        expect(credit_payment.amount).to eq(6.00) # order.total is 10.00
      end
    end

    context "with an order with a guest checkout" do
      let(:order) {
        create(:order_with_line_items, line_items_count: 1, distributor:, order_cycle:, customer:)
      }
      let(:customer) { create(:customer, enterprise: distributor, user: nil) }

      it "doesn't add credit even if the customer has credit available" do
        # Add credit
        create(
          :customer_account_transaction,
          amount: 100.00,
          customer: order.customer
        )

        subject.apply

        expect(order.payments.where(payment_method: credit_payment_method)).to be_empty
      end
    end
  end

  describe "#refund" do
    let(:order) { create(:completed_order_with_fees) }

    before do
      # Overpay to put the order payment state in "credit_owed"
      payment = order.payments.first
      payment.complete!
      payment.update(amount: 48.00)
      order.update_order!
    end

    it "adds a customer credit payment to the order" do
      expect { subject.refund(user: ) }.to change { order.payments.count }.by(1)

      last_payment = order.payments.reload.order(:id).last
      expect(last_payment.payment_method).to eq(credit_payment_method)
      expect(last_payment.amount).to eq(-12.00)
      expect(last_payment.state).to eq("completed")

      expect(order.payment_state).to eq("paid")
    end

    it "adds an entry in customer account transaction" do
      subject.refund(user: )

      last_transaction = order.customer.customer_account_transactions.last
      expect(last_transaction.amount).to eq(12.00)
      expect(last_transaction.created_by).to eq(user)
    end

    it "returns sucessful reponse" do
      response = subject.refund(user: )

      expect(response.success?).to eq(true)
      expect(response.message).to eq("Refund successful!")
    end

    context "when order payment state is not 'credit_owed'" do
      before do
        order.update(payment_state: "paid")
      end

      it "does nothing" do
        expect { subject.refund }.not_to change { order.payments.count }
      end

      it "returns a failed respond" do
        response = subject.refund

        expect(response.failure?).to eq(true)
        expect(response.message).to eq("No credit owed")
      end
    end

    context "when the order has no customer" do
      before do
        order.update_column(:customer_id, nil)
        order.reload
      end

      it "returns a descriptive failure without changing payments or customer credit" do
        expect {
          response = subject.refund(user:)

          expect(response.failure?).to eq(true)
          expect(response.message).to eq("No customer is assigned to this order")
        }.not_to change { [order.payments.count, CustomerAccountTransaction.count] }

        expect(order.reload.payment_state).to eq("credit_owed")
        expect(order.new_outstanding_balance).to eq(-12.00)
      end
    end

    context "when payment creation fails" do
      before do
        failed_response = ActiveMerchant::Billing::Response.new(false, "Void error")
        allow_any_instance_of(Spree::PaymentMethod::CustomerCredit).to receive(:void)
          .and_return(failed_response)
      end

      it "logs the error" do
        expect(Alert).to receive(:raise).with(RuntimeError)
        subject.refund
      end

      it "doesn't create a credit payment" do
        # We use `length` to check the payments in memory
        expect { subject.refund }.not_to change { order.payments.length }
      end

      it "returns a failed response" do
        response = subject.refund

        expect(response.failure?).to eq(true)
        expect(response.message).to eq(RuntimeError.new("Void error").to_s)
      end
    end
  end

  describe "#pay_order" do
    # Total is 36.00: items 20.00 + shipping 6.00 + cash payment fee 10.00
    # The cash payment is still in "checkout" state, so the order has a balance due
    let(:order) { create(:completed_order_with_fees) }
    let(:cash_payment) { order.payments.first }
    let(:customer) { order.customer }

    context "when the credit covers the balance due" do
      before { create(:customer_account_transaction, amount: 100.00, customer:) }

      it "pays the order with a completed credit payment" do
        subject.pay_order(user:)

        credit_payment = order.payments.customer_credit.last
        expect(credit_payment.state).to eq("completed")
        expect(credit_payment.amount).to eq(26.00)
        expect(order.reload.payment_state).to eq("paid")
      end

      it "voids the cash payment and drops its fee" do
        subject.pay_order(user:)

        expect(cash_payment.reload.state).to eq("void")
        expect(order.reload.total).to eq(26.00)
        expect(order.payments.incomplete).to be_empty
      end

      it "debits the customer account and records who did it" do
        subject.pay_order(user:)

        transaction = customer.customer_account_transactions.last
        expect(transaction.amount).to eq(-26.00)
        expect(transaction.created_by).to eq(user)
        expect(customer.credit_balance).to eq(74.00)
      end

      it "returns a successful response" do
        response = subject.pay_order(user:)

        expect(response.success?).to eq(true)
        expect(response.message).to eq("$26.00 of customer credit used to pay this order")
      end
    end

    context "when the credit covers part of the balance due" do
      before { create(:customer_account_transaction, amount: 20.00, customer:) }

      it "pays with all the available credit and leaves the rest due" do
        subject.pay_order(user:)

        credit_payment = order.payments.customer_credit.last
        expect(credit_payment.state).to eq("completed")
        expect(credit_payment.amount).to eq(20.00)
        expect(customer.credit_balance).to eq(0.00)
        expect(cash_payment.reload.state).to eq("void")
        expect(order.reload.payment_state).to eq("balance_due")
        expect(order.new_outstanding_balance).to eq(6.00)
      end
    end

    context "when part of the order is already paid" do
      before do
        create(:customer_account_transaction, amount: 100.00, customer:)
        # Replaces the pending cash payment (and its fee): total 26.00, 10.00 paid
        create(:payment, order:, amount: 10.00, state: "completed",
                         payment_method: create(:payment_method, distributors: [order.distributor]))
        order.update_order!
      end

      it "only pays what is left" do
        subject.pay_order(user:)

        expect(order.payments.customer_credit.last.amount).to eq(16.00)
        expect(order.reload.payment_state).to eq("paid")
      end
    end

    context "when the order is resumed" do
      before do
        create(:customer_account_transaction, amount: 100.00, customer:)
        order.update_columns(state: "resumed")
      end

      it "pays the order" do
        expect(subject.pay_order(user:).success?).to eq(true)
        expect(order.reload.payment_state).to eq("paid")
      end
    end

    describe "when the order can't be paid with credit" do
      before { create(:customer_account_transaction, amount: 100.00, customer:) }

      shared_examples "no payment with credit" do |message|
        it "returns a failed response and doesn't change the order" do
          expect {
            response = subject.pay_order(user:)

            expect(response.failure?).to eq(true)
            expect(response.message).to eq(message)
          }.not_to change { order.payments.reload.map(&:state) }

          expect(order.payments.customer_credit).to be_empty
        end
      end

      context "without user" do
        let(:user) { nil }

        it_behaves_like "no payment with credit", "A user is required to pay with credit"
      end

      context "without customer" do
        before { order.update_columns(customer_id: nil) }

        it_behaves_like "no payment with credit", "The customer has no credit available"
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
        allow_any_instance_of(Spree::Payment).to receive(:internal_purchase!)
          .and_raise(Spree::Core::GatewayError, "Purchase error")
      end

      it "logs the error" do
        expect(Alert).to receive(:raise).with(Spree::Core::GatewayError)
        subject.pay_order(user:)
      end

      it "leaves the order and the customer account unchanged" do
        subject.pay_order(user:)

        expect(order.payments.reload.customer_credit).to be_empty
        expect(cash_payment.reload.state).to eq("checkout")
        expect(order.reload.total).to eq(36.00)
        expect(customer.credit_balance).to eq(100.00)
      end

      it "returns a failed response" do
        response = subject.pay_order(user:)

        expect(response.failure?).to eq(true)
        expect(response.message).to eq("Purchase error")
      end
    end
  end
end
