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

  describe "through the order lifecycle" do
    # Shopfront checkout, subscriptions (PlaceProxyOrder) and orders created in the back office
    # all advance the order with Orders::WorkflowService.
    let(:order) {
      create(:order_with_totals_and_distribution, distributor:, customer:,
                                                  bill_address: create(:address),
                                                  ship_address: create(:address),
                                                  payments: [create(:payment)])
    }

    before { carry_over(0.57) }

    it "adds the balance due and settles it when the order completes" do
      Orders::WorkflowService.new(order).complete!

      expect(order.reload.state).to eq("complete")
      expect(balance_due_adjustments.first.amount).to eq(0.57)
      expect(customer.reload.credit_balance).to eq(0.00)
    end

    it "locks the balance due once the order is complete" do
      Orders::WorkflowService.new(order).complete!

      expect(balance_due_adjustments.first.state).to eq("finalized")
    end

    it "updates the balance due if it changes before confirmation" do
      Orders::WorkflowService.new(order).advance_to_payment
      expect(balance_due_adjustments.first.amount).to eq(0.57)

      # The hub waives part of the balance while the customer is checking out
      create(:customer_account_transaction, customer:, amount: 0.20)
      order.next!

      expect(order.state).to eq("confirmation")
      expect(balance_due_adjustments.first.amount).to eq(0.37)
    end

    context "when the completed order is cancelled" do
      before do
        Orders::WorkflowService.new(order).complete!
        order.cancel!
      end

      it "restores the balance due on the customer's account" do
        expect(customer.reload.credit_balance).to eq(-0.57)
        expect(customer.customer_account_transactions.last.description).to eq(
          "Balance due restored: order #{order.number} was cancelled"
        )
      end

      it "settles the balance again if the order is resumed" do
        # In the app, resuming happens in a later request that loads the order afresh
        order.reload.resume!

        expect(customer.reload.credit_balance).to eq(0.00)
      end

      it "restores the balance again if the resumed order is cancelled again" do
        order.reload.resume!
        order.reload.cancel!

        expect(customer.reload.credit_balance).to eq(-0.57)
      end
    end
  end

  describe "#restore" do
    before do
      carry_over(0.57)
      subject.apply
    end

    it "only restores a balance that was settled" do
      expect { subject.restore }.not_to change { CustomerAccountTransaction.count }
    end

    it "only restores once" do
      subject.settle
      subject.restore
      subject.restore

      expect(customer.reload.credit_balance).to eq(-0.57)
    end

    context "when the order was settled in another language" do
      before do
        I18n.backend.store_translations(
          :es, balance_due_service: { paid_description: "Pagado en el pedido %{order_number}" }
        )
      end

      after { I18n.reload! }

      it "still restores the balance" do
        I18n.with_locale(:es) { subject.settle }
        subject.restore

        expect(customer.reload.credit_balance).to eq(-0.57)
      end
    end
  end
end
