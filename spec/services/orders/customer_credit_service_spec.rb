# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Orders::CustomerCreditService do
  subject { described_class.new(order) }

  let(:distributor) { create(:distributor_enterprise) }
  let(:order_cycle) { create(:order_cycle, distributors: [distributor]) }
  let(:credit_payment_method) { order.distributor.payment_methods.customer_credit }
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
        customer: order.customer,
        payment_method: credit_payment_method
      )
      subject.apply

      credit_payment = order.payments.find_by(payment_method: credit_payment_method)
      expect(credit_payment).to be_present
      expect(credit_payment.amount).to eq(10.00) # order.total is 10.00
    end

    context "when no credit available" do
      it "doesn't add a customer credit payment" do
        subject.apply

        credit_payment = order.payments.where(payment_method: credit_payment_method)
        expect(order.payments.where(payment_method: credit_payment_method)).to be_empty
      end
    end

    context "when credit payment already added" do
      it "doesn't had more credit payment" do
        create(
          :customer_account_transaction,
          amount: 100.00,
          customer: order.customer,
          payment_method: credit_payment_method
        )
        subject.apply

        credit_payment = order.payments.find_by(payment_method: credit_payment_method)
        expect(credit_payment).to be_present

        subject.apply

        credit_payments = order.payments.where(payment_method: credit_payment_method)
        expect(order.payments.where(payment_method: credit_payment_method).count).to eq(1)
      end
    end

    context "when no enought credit available" do
      it "adds credit payment using all credit" do
        # Add credit
        create(
          :customer_account_transaction,
          amount: 5.00,
          customer: order.customer,
          payment_method: credit_payment_method
        )
        subject.apply

        credit_payment = order.payments.find_by(payment_method: credit_payment_method)
        expect(credit_payment.amount).to eq(5.00)
      end
    end

    context "when payment creation fails" do
      before do
        # Add credit
        create(
          :customer_account_transaction,
          amount: 5.00,
          customer: order.customer,
          payment_method: credit_payment_method
        )
        allow_any_instance_of(Spree::Payment).to receive(:internal_purchase!)
          .and_raise(Spree::Core::GatewayError)
      end

      it "logs the error" do
        expect(Alert).to receive(:raise).with(Spree::Core::GatewayError)
        subject.apply
      end

      it "doesn't create a credit payment" do
        subject.apply

        credit_payment = order.payments.find_by(payment_method: credit_payment_method)
        expect(credit_payment).to be_nil
      end
    end

    context "when credit payment method is missing" do
      before do
        # Add credit
        payment_method = order.customer.enterprise.payment_methods.internal.find_by(
          name: Rails.application.config.api_payment_method[:name]
        )
        create(
          :customer_account_transaction,
          amount: 5.00,
          customer: order.customer,
          payment_method:
        )
        credit_payment_method.destroy!
      end

      it "logs the error" do
        expect(Alert).to receive(:raise).with(
          "Customer credit payment method is missing, please check configuration"
        )
        subject.apply
      end

      it "doesn't create a credit payment" do
        subject.apply

        expect(order.payments).to be_empty
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
      expect(last_transaction.payment_method).to eq(credit_payment_method)
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

    context "when credit payment method is missing" do
      before do
        credit_payment_method.destroy!
      end

      it "logs the error" do
        expect(Alert).to receive(:raise).with(
          "Customer credit payment method is missing, please check configuration"
        )
        subject.refund
      end

      it "doesn't create a credit payment" do
        expect { subject.refund }.not_to change { order.payments.count }
      end

      it "returns a failed response" do
        response = subject.refund

        expect(response.failure?).to be(true)
        expect(response.message).to eq(
          "Customer credit payment method is missing, please check configuration"
        )
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
