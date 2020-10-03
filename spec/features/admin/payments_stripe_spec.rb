require 'spec_helper'

feature '
    As an hub manager
    I want to make Stripe payments
' do
  include AuthenticationHelper

  let(:order) { create(:completed_order_with_fees) }

  context "with a payment using a StripeSCA payment method" do
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
