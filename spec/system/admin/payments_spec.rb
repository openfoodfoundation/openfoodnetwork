# frozen_string_literal: true

require 'system_helper'

RSpec.describe '
    As an admin
    I want to manage payments
' do
  include AuthenticationHelper

  let(:order) { create(:completed_order_with_fees) }
  let(:confirmed_order) { create(:order_ready_for_confirmation) }

  describe "payments/new" do
    it "displays the order balance as the default payment amount" do
      login_as_admin
      visit spree.new_admin_order_payment_path order

      expect(page).to have_content 'New Payment'
      expect(page).to have_field(:payment_amount, with: order.outstanding_balance.to_f)
    end
  end

  context "with sensitive payment fee" do
    before do
      payment_method = create(:payment_method, distributors: [order.distributor])

      # This calculator doesn't handle a `nil` order well.
      # That has been useful in finding bugs. ;-)
      payment_method.calculator = Calculator::FlatPercentItemTotal.new
      payment_method.save!
    end

    it "renders the new payment page" do
      login_as_admin
      visit spree.new_admin_order_payment_path order

      expect(page).to have_content 'New Payment'
    end
  end

  context "creating an order's first payment via admin" do
    before do
      order.update_columns(
        state: "payment",
        payment_state: nil,
        shipment_state: nil,
        completed_at: nil
      )
    end

    it "creates the payment, completes the order, and updates payment and shipping states" do
      login_as_admin
      visit spree.new_admin_order_payment_path order

      expect(page).to have_content "New Payment"

      within "#new_payment" do
        find('input[type="radio"]').click
      end

      click_button "Update"
      expect(page).to have_content "Payments"
      expect(page).to have_content "Payment has been successfully created!"
      expect(page).not_to have_content "[object Object]true"

      order.reload
      expect(order.state).to eq "complete"
      expect(order.payment_state).to eq "balance_due"
      expect(order.shipment_state).to eq "pending"
    end
  end

  describe 'Capture & complete order' do
    it 'completes order when capturing payment' do
      login_as_admin
      visit spree.admin_order_payments_path confirmed_order
      expect(page).to have_content "CHECKOUT"
      page.find('a.icon-capture_and_complete_order').click
      expect(confirmed_order.reload.state).to eq 'complete'
    end
  end

  describe "Pay with credit" do
    # Order total is $36.00, including a $10.00 fee for the pending cash payment
    let(:customer) { order.customer }

    before do
      login_as_admin
    end

    context "when the customer has enough credit" do
      before { create(:customer_account_transaction, amount: 100, customer:) }

      it "pays the order with the customer's credit" do
        visit spree.admin_order_payments_path(order)

        expect(page).to have_content "AVAILABLE CREDIT : $100.00"

        accept_confirm do
          click_link "Pay with credit"
        end

        expect(page).to have_content "$26.00 of customer credit used to pay this order"
        expect(page).to have_content "AVAILABLE CREDIT : $74.00"
        expect(page).not_to have_link "Pay with credit"
        within "table.index" do
          expect(page).to have_content "Customer credit"
          expect(page).to have_content "COMPLETED"
          expect(page).to have_content "INVALID"
        end
        expect(order.reload.payment_state).to eq "paid"
      end
    end

    context "when the customer has less credit than the balance due" do
      before { create(:customer_account_transaction, amount: 20, customer:) }

      it "keeps a cash payment for the remaining amount" do
        visit spree.admin_order_payments_path(order)

        accept_confirm do
          click_link "Pay with credit"
        end

        expect(page).to have_content "$20.00 of customer credit used to pay this order"
        expect(page).to have_content "BALANCE DUE : $16.00"
        expect(page).not_to have_content "AVAILABLE CREDIT"
        expect(page).to have_link "New Payment"
        expect(page).not_to have_link "Pay with credit"
      end
    end

    context "when a card payment is pending" do
      before do
        create(:customer_account_transaction, amount: 100, customer:)
        stripe = create(:stripe_sca_payment_method, distributors: [order.distributor])
        create(:payment, order:, payment_method: stripe, amount: order.total, state: "pending")
      end

      it "asks to void the card payment first" do
        visit spree.admin_order_payments_path(order)

        expect(page).to have_content "AVAILABLE CREDIT : $100.00"
        expect(page).to have_content "This order has a pending StripeSCA payment. " \
                                     "Void it before paying with credit."
        expect(page).not_to have_link "Pay with credit"
      end
    end

    context "when the customer has no credit" do
      it "doesn't offer to pay with credit" do
        visit spree.admin_order_payments_path(order)

        expect(page).to have_content "BALANCE DUE : $36.00"
        expect(page).not_to have_content "AVAILABLE CREDIT"
        expect(page).not_to have_link "Pay with credit"
      end
    end
  end
end
