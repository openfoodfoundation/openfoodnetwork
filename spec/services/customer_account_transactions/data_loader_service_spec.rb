# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CustomerAccountTransactions::DataLoaderService do
  subject { described_class.new(user:, enterprise:) }

  let(:user) { create(:user) }
  let(:enterprise) { create(:distributor_enterprise) }

  describe "#customer_account_transactions" do
    it "returns a list of customer payments ordered by newest" do
      customer = create(:customer, email: user.email, enterprise:)
      user.customers << customer
      customer_account_transactions = create_list(:customer_account_transaction, 3, customer:)

      expect(subject.customer_account_transactions).to eq([
                                                            customer_account_transactions.third,
                                                            customer_account_transactions.second,
                                                            customer_account_transactions.first,
                                                          ])
    end

    context "with no customer associated with the user" do
      it "returns an empty array" do
        expect(subject.customer_account_transactions).to eq([])
      end
    end

    context "with no customer associated with the given enterprise" do
      it "returns an empty array" do
        customer = create(:customer, email: user.email)
        user.customers << customer

        expect(subject.customer_account_transactions).to eq([])
      end
    end
  end

  describe "#available_credit" do
    it "returns the total credit availble to the user" do
      customer = create(:customer, email: user.email, enterprise:)
      user.customers << customer
      create(:customer_account_transaction, customer:, amount: 10.00)
      create(:customer_account_transaction, customer:, amount: -2.00)
      create(:customer_account_transaction, customer:, amount: 5.00)

      expect(subject.available_credit).to eq(13.00)
    end

    context "with no customer associated with the user" do
      it "returns 0" do
        expect(subject.available_credit).to eq(0)
      end
    end

    context "with no customer associated with the given enterprise" do
      it "returns 0" do
        customer = create(:customer, email: user.email)
        user.customers << customer

        expect(subject.available_credit).to eq(0)
      end
    end
  end
end
