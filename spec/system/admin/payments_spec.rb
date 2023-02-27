# frozen_string_literal: true

require 'system_helper'

describe '
    As an admin
    I want to manage payments
' do
  include AuthenticationHelper

  let(:order) { create(:completed_order_with_fees) }

  describe "payments/new" do
    it "displays the order balance as the default payment amount" do
      login_as_admin_and_visit spree.new_admin_order_payment_path order

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
      login_as_admin_and_visit spree.new_admin_order_payment_path order

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
      login_as_admin_and_visit spree.new_admin_order_payment_path order

      expect(page).to have_content "New Payment"

      within "#new_payment" do
        find('input[type="radio"]').click
      end

      click_button "Update"
      expect(page).to have_content "Payments"

      order.reload
      expect(order.state).to eq "complete"
      expect(order.payment_state).to eq "balance_due"
      expect(order.shipment_state).to eq "pending"
    end
  end
end
