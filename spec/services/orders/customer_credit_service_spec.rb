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

        credit_payment = order.payments.where(payment_method: credit_payment_method)
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

    context "when no enought credit available" do
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
end
