require 'spec_helper'

feature '
    As an admin
    I want to manage payments
' do
  include AuthenticationHelper

  let(:order) { create(:completed_order_with_fees) }

  scenario "visiting the payment form" do
    login_as_admin_and_visit spree.new_admin_order_payment_path order

    expect(page).to have_content "New Payment"
  end

  context "with sensitive payment fee" do
    before do
      payment_method = create(:payment_method, distributors: [order.distributor])

      # This calculator doesn't handle a `nil` order well.
      # That has been useful in finding bugs. ;-)
      payment_method.calculator = Calculator::FlatPercentItemTotal.new
      payment_method.save!
    end

    scenario "visiting the payment form" do
      login_as_admin_and_visit spree.new_admin_order_payment_path order

      expect(page).to have_content "New Payment"
    end
  end

  context "with a StripeSCA payment method" do
    before do
      stripe_payment_method = create(:stripe_sca_payment_method, distributors: [order.distributor])
      order.payments << create(:payment, payment_method: stripe_payment_method, order: order)
    end

    it "renders the payment details" do
      login_as_admin_and_visit spree.admin_order_payments_path order

      page.click_link("StripeSCA")
      expect(page).to have_content order.payments.last.source.last_digits
    end

    context "with a deleted credit card" do
      before do
        order.payments.last.update_attribute(:source, nil)
      end

      it "renders the payment details" do
        login_as_admin_and_visit spree.admin_order_payments_path order

        page.click_link("StripeSCA")
        expect(page).to have_content order.payments.last.amount
      end
    end
  end
end
