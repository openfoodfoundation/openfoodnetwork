# frozen_string_literal: true

require "spec_helper"

RSpec.describe Spree::PaymentMethod::CustomerCredit do
  subject { build(:customer_credit_payment_method) }

  describe "#name" do
    it { expect(subject.name).to eq("credit_payment_method.name") }
  end

  describe "#description" do
    it { expect(subject.description).to eq("credit_payment_method.description") }
  end

  describe "#purchase" do
    let(:response) { subject.purchase(amount, nil, options) }

    let!(:credit_payment_method) { create(:customer_credit_payment_method) }
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
      expect(response.message).to eq("Payment with credit was sucessful")
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

  describe "#void" do
    let(:response) { subject.void(amount, nil, options) }
    let(:amount) { 1500 } # in cents
    let(:options) {
      {
        customer_id: customer.id,
        payment_id: payment.id,
        order_number: "R023075164"
      }
    }
    let(:customer) { create(:customer) }
    let!(:payment) { create(:payment, payment_method: credit_payment_method) }
    let!(:credit_payment_method) { create(:customer_credit_payment_method) }

    it "returns a success response" do
      expect(response).to be_a(ActiveMerchant::Billing::Response)
      expect(response.success?).to be(true)
      expect(response.message).to eq("Credit void was sucessful")
    end

    it "credits the payment to customer the account transaction" do
      expect(response.success?).to be(true)

      transaction = customer.customer_account_transactions.last
      expect(transaction.amount).to eq(15.00)
      expect(transaction.payment_method).to be_a(Spree::PaymentMethod::CustomerCredit)
      expect(transaction.payment).to eq(payment)
      expect(transaction.description).to eq("Refund for order: R023075164")
    end

    context "when user_id provided" do
      let(:user) { create(:enterprise_user) }
      let(:options) {
        {
          customer_id: customer.id,
          payment_id: payment.id,
          order_number: "R023075164",
          user_id: user.id
        }
      }

      it "links the customer account transaction to the user" do
        expect(response.success?).to be(true)

        transaction = customer.customer_account_transactions.last
        expect(transaction.created_by).to eq(user)
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
