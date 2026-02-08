# frozen_string_literal: true

require "spec_helper"

RSpec.describe Spree::PaymentMethod::CustomerCredit do
  subject { build(:customer_credit_payment_method) }

  describe "#name" do
    subject { build(:customer_credit_payment_method, name:) }

    let(:name) { "credit_payment_method.name" }

    it "translate the name" do
      expect(subject.name).to eq("Customer credit")
    end

    context "when not a tranlatable string" do
      let(:name) { "customer credit payment" }

      it "falls back to no translation" do
        expect(subject.name).to eq("customer credit payment")
      end
    end
  end

  describe "#description" do
    subject { build(:customer_credit_payment_method, description:) }

    let(:description) { "credit_payment_method.description" }

    it "translate the name" do
      expect(subject.description).to eq("Allow customer to pay with credit")
    end

    context "when not a tranlatable string" do
      let(:description) { "Payment method to allow customer to pay with credit" }

      it "falls back to no translation" do
        expect(subject.description).to eq("Payment method to allow customer to pay with credit")
      end
    end
  end

  describe "#purchase" do
    let(:response) { subject.purchase(amount, nil, options) }

    let!(:payment_method) {
      create(:payment_method, name: CustomerAccountTransaction::DEFAULT_PAYMENT_METHOD_NAME)
    }
    let!(:credit_payment_method) {
      create(:customer_credit_payment_method)
    }
    let(:amount) { 1000 } # in cents
    let(:options) {
      {
        customer_id: customer.id,
        payment_id: payment.id,
        order_number: "R023075164"
      }
    }
    let(:customer) { create(:customer) }
    let!(:payment) { create(:payment, payment_method: credit_payment_method) }

    it "returns a success response" do
      create(:customer_account_transaction, amount: 25.00, customer:)

      expect(response).to be_a(ActiveMerchant::Billing::Response)
      expect(response.success?).to be(true)
    end

    it "debits the payment from customer the account transaction" do
      create(:customer_account_transaction, amount: 25.00, customer:)

      expect(response.success?).to be(true)

      transaction = customer.customer_account_transactions.last
      expect(transaction.amount).to eq(-10.00)
      expect(transaction.payment_method).to be_a(Spree::PaymentMethod::CustomerCredit)
      expect(transaction.payment).to eq(payment)
      expect(transaction.description).to eq("Payment for order: R023075164")
    end

    context "when not enough credit is available" do
      let!(:customer_credit) { create(:customer_account_transaction, amount: 5.00, customer:) }

      it "returns an error" do
        expect(response.success?).to be(false)
        expect(response.message).to eq("Not enough credit available")
      end

      it "doesn't debit the customer account transaction" do
        expect(CustomerAccountTransaction.where(customer: customer).last).to eq(customer_credit)
      end
    end

    context "when no credit available" do
      it "returns an error" do
        expect(response.success?).to be(false)
        expect(response.message).to eq("No credit available")
      end
    end

    context "when customer doesn't exist" do
      let(:customer) { nil }
      let(:options) {
        {
          customer_id: -1,
          payment_id: payment.id
        }
      }

      it "returns an error" do
        expect(response.success?).to be(false)
        expect(response.message).to eq("Customer not found")
      end
    end

    context "when payment is missing" do
      let(:options) {
        {
          customer_id: customer.id,
        }
      }

      it "returns an error" do
        expect(response.success?).to be(false)
        expect(response.message).to eq("Missing payment")
      end
    end

    context "when credit payment method is not configured" do
      let!(:credit_payment_method) { nil }

      it "returns an error" do
        expect(response.success?).to be(false)
        expect(response.message).to eq("Credit payment method is missing")
      end
    end
  end
end
