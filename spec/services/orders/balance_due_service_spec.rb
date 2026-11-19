# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Orders::BalanceDueService do
  subject { described_class.new(order) }

  let(:distributor) { create(:distributor_enterprise) }
  let(:order_cycle) { create(:order_cycle, distributors: [distributor]) }
  let(:customer) { create(:customer, enterprise: distributor) }
  let(:order) {
    create(:order_with_line_items, line_items_count: 1, distributor:, order_cycle:, customer:)
  }
  let(:previous_order) { create(:order, distributor:, customer:) }

  def carry_over(amount, from: previous_order)
    payment = create(:payment, order: from, amount:, state: "completed")
    create(:customer_account_transaction, customer:, amount: -amount, payment:)
  end

  def balance_due_adjustments
    order.all_adjustments.where(originator_type: "Customer")
  end

  describe "#apply" do
    context "when the customer has a negative balance" do
      before { carry_over(0.57) }

      it "adds the balance due to the order" do
        expect { subject.apply }.to change { order.reload.total }.by(0.57)

        adjustment = balance_due_adjustments.first
        expect(adjustment.amount).to eq(0.57)
        expect(adjustment.originator).to eq(customer)
        expect(adjustment.label).to eq(
          "Balance due from previous order(s) #{previous_order.number}"
        )
      end

      it "doesn't add tax to the balance due" do
        subject.apply

        expect(balance_due_adjustments.first.tax_category).to be_nil
      end

      it "only adds the balance due once when applied again" do
        subject.apply
        subject.apply

        expect(balance_due_adjustments.count).to eq(1)
        expect(order.reload.total).to eq(10.57) # order item total is 10.00
      end

      it "lists every order the balance came from" do
        other_order = create(:order, distributor:, customer:)
        carry_over(1.00, from: other_order)

        subject.apply

        adjustment = balance_due_adjustments.first
        expect(adjustment.amount).to eq(1.57)
        expect(adjustment.label).to eq(
          "Balance due from previous order(s) #{previous_order.number}, #{other_order.number}"
        )
      end
    end

    context "when the balance was paid off before re-applying" do
      it "removes the balance due" do
        carry_over(0.57)
        subject.apply

        create(:customer_account_transaction, customer:, amount: 0.57)
        subject.apply

        expect(balance_due_adjustments).to be_empty
        expect(order.reload.total).to eq(10.00)
      end
    end

    context "when the customer has no balance due" do
      it "doesn't add anything" do
        create(:customer_account_transaction, customer:, amount: 5.00)

        subject.apply

        expect(balance_due_adjustments).to be_empty
      end
    end

    context "when the customer is a guest" do
      let(:customer) { create(:customer, enterprise: distributor, user: nil) }

      it "doesn't add anything" do
        carry_over(0.57)

        subject.apply

        expect(balance_due_adjustments).to be_empty
      end
    end
  end

  describe "#settle" do
    before do
      carry_over(0.57)
      subject.apply
    end

    it "brings the customer's balance back to zero" do
      subject.settle

      expect(customer.reload.credit_balance).to eq(0.00)
      expect(customer.customer_account_transactions.last.description).to eq(
        "Balance due paid on order #{order.number}"
      )
    end

    it "only settles once" do
      subject.settle
      subject.settle

      expect(customer.customer_account_transactions.count).to eq(2)
      expect(customer.reload.credit_balance).to eq(0.00)
    end

    context "when the order has no balance due" do
      it "doesn't create a transaction" do
        balance_due_adjustments.destroy_all

        expect { subject.settle }.not_to change { CustomerAccountTransaction.count }
      end
    end
  end
end
