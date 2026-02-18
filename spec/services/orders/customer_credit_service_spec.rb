# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Orders::CustomerCreditService do
  subject { described_class.new(order) }

  let(:order) {
    create(:order_with_line_items, line_items_count: 1, distributor:, order_cycle:,
                                   customer: create(:customer, enterprise: distributor))
  }
  let(:distributor) { create(:distributor_enterprise) }
  let(:order_cycle) { create(:order_cycle, distributors: [distributor]) }
  let(:credit_payment_method) { order.distributor.payment_methods.customer_credit }

  describe "#apply" do
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
        create(
          :customer_account_transaction,
          amount: 5.00,
          customer: order.customer,
          payment_method: credit_payment_method
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
end
