require 'spec_helper'

feature '
    As an hub manager
    I want to make Stripe payments
' do
  include AuthenticationHelper
  include StripeHelper

  let!(:order) { create(:completed_order_with_fees) }
  let!(:stripe_payment_method) { create(:stripe_sca_payment_method, distributors: [order.distributor]) }

  context "with a payment using a StripeSCA payment method" do
    before do
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

  context "making a new Stripe payment" do
    let!(:stripe_account) { create(:stripe_account, enterprise: order.distributor, stripe_user_id: "abc123") }

    before do
      stub_hub_payment_methods_request
      stub_payment_intents_post_request order: order, stripe_account_header: true
      stub_payment_intent_get_request
      stub_successful_capture_request order: order
    end

    it "adds a payment with state complete", js: true do
      login_as_admin_and_visit spree.new_admin_order_payment_path order

      choose "StripeSCA"
      fill_in "payment_amount", with: order.total.to_s
      fill_in "cardholder_name", with: "David Gilmour"
      fill_in "stripe-cardnumber", with: "4242424242424242"
      fill_in "exp-date", with: "01-01-2050"
      fill_in "cvc", with: "678"
      click_button "Update"

      expect(page).to have_link "StripeSCA"
      expect(order.payments.reload.first.state).to eq "completed"
    end
  end
end
