# frozen_string_literal: true

require 'spec_helper'

feature '
    As an admin
    I want to manage payments
' do
  include AuthenticationHelper

  let(:order) { create(:completed_order_with_fees) }

  describe "payments/new" do
    it "displays the order balance as the default payment amount" do
      login_as_admin_and_visit spree.new_admin_order_payment_path order

      expect(page).to have_content I18n.t(:new_payment)
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

      expect(page).to have_content I18n.t(:new_payment)
    end
  end
end
