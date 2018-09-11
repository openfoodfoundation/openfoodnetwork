require 'spec_helper'

feature '
    As an admin
    I want to manage payments
' do
  include AuthenticationWorkflow

  let(:order) { create(:completed_order_with_fees) }

  scenario "visiting the payment form" do
    quick_login_as_admin

    visit spree.new_admin_order_payment_path order

    expect(page).to have_content "New Payment"
  end

  context "with sensitive payment fee" do
    let(:payment_method) { order.distributor.payment_methods.first }

    before do
      # This calculator doesn't handle a `nil` order well.
      # That has been useful in finding bugs. ;-)
      payment_method.calculator = Spree::Calculator::FlatPercentItemTotal.new
      payment_method.save!
    end

    scenario "visiting the payment form" do
      pending "fix usage of the PaymentMethodSerializer"
      quick_login_as_admin

      visit spree.new_admin_order_payment_path order

      expect(page).to have_content "New Payment"
    end
  end
end
