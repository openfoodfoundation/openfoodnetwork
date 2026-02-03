# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CustomerAccountTransaction do
  let!(:payment_method) {
    create(:payment_method, name: CustomerAccountTransaction::DEFAULT_PAYMENT_METHOD_NAME)
  }

  describe "validations" do
    subject { build(:customer_account_transaction) }

    it { is_expected.to belong_to(:customer) }
    it { is_expected.to validate_presence_of(:amount) }
    it { is_expected.to validate_presence_of(:currency) }
    it { is_expected.to belong_to(:payment_method) }
    it { is_expected.to belong_to(:payment).optional }
  end

  describe "readonly" do
    it "record are readonly" do
      transaction = create(:customer_account_transaction, amount: 9.00)

      expect { transaction.update!(amount: 22.00) }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end
  end

  context "extends LocalizedNumber" do
    subject { build_stubbed(:customer_account_transaction) }

    it_behaves_like "a model using the LocalizedNumber module", [:amount]
  end

  describe "#balance" do
    it "calculate the balance on creation for the given customer" do
      customer = create(:customer)
      create(:customer_account_transaction, amount: 15.00, customer: )
      create(:customer_account_transaction, amount: 10.00)
      transaction = create(:customer_account_transaction, amount: 9.00, customer: )

      expect(transaction.reload.balance).to eq(24.00)
    end

    context "when no existing balance" do
      it "creates an 'account creation' transaction" do
        customer = create(:customer)
        transaction = create(:customer_account_transaction, amount: 12.00, customer:)

        first_transaction = CustomerAccountTransaction.where(customer: customer).first
        expect(first_transaction.amount).to eq(0.00)
        expect(first_transaction.description).to eq("Account creation")
      end

      it "set the balance to the new transaction's amount" do
        transaction = create(:customer_account_transaction, amount: 12.00)

        res = CustomerAccountTransaction.where(customer: transaction.customer).last
        expect(res.balance).to eq(12.00)
      end
    end

    context "when the default payment method is missing" do
      let!(:payment_method) { nil }

      it "raises an error" do
        expect { create(:customer_account_transaction, amount: 12.00) }.to raise_error(
          ActiveRecord::RecordNotFound
        )
      end
    end
  end
end
