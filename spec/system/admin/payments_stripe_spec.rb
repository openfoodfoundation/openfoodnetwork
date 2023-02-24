# frozen_string_literal: true

require 'system_helper'

describe '
    As an hub manager
    I want to make Stripe payments
' do
  include AuthenticationHelper
  include StripeHelper
  include StripeStubs

  let!(:order) { create(:completed_order_with_fees) }
  let!(:stripe_payment_method) do
    create(:stripe_sca_payment_method, distributors: [order.distributor])
  end
  let!(:stripe_account) do
    create(:stripe_account, enterprise: order.distributor, stripe_user_id: "abc123")
  end

  around do |example|
    with_stripe_setup { example.run }
  end

  context "making a new Stripe payment" do
    before do
      stub_payment_methods_post_request
      stub_payment_intent_get_request
      stub_retrieve_payment_method_request("pm_123")
      stub_list_customers_request(email: order.user.email, response: {})
      stub_get_customer_payment_methods_request(customer: "cus_A456", response: {})
    end

    context "for a complete order" do
      context "with a card that succeeds on card registration" do
        before { stub_payment_intents_post_request order: order, stripe_account_header: true }

        context "and succeeds on payment capture" do
          before { stub_successful_capture_request order: order }

          it "adds a payment with state complete" do
            login_as_admin_and_visit spree.new_admin_order_payment_path order

            fill_in "payment_amount", with: order.total.to_s
            fill_in_card_details_in_backoffice
            click_button "Update"

            expect(page).to have_link "StripeSCA"
            expect(OrderPaymentFinder.new(order.reload).last_payment.state).to eq "completed"
          end
        end

        context "but fails on payment capture" do
          let(:error_message) { "Card was declined: insufficient funds." }

          before { stub_failed_capture_request order: order, response: { message: error_message } }

          it "fails to add a payment due to card error" do
            login_as_admin_and_visit spree.new_admin_order_payment_path order

            fill_in "payment_amount", with: order.total.to_s
            fill_in_card_details_in_backoffice
            click_button "Update"

            expect(page).to have_link "StripeSCA"
            expect(page).to have_content "FAILED"
            expect(OrderPaymentFinder.new(order.reload).last_payment.state).to eq "failed"
          end
        end
      end

      context "with a card that fails on registration because it requires(redirects) extra auth" do
        before do
          stub_payment_intents_post_request_with_redirect order: order,
                                                          redirect_url: "https://www.stripe.com/authorize"
        end

        it "adds the payment and it is in the requires_authorization state" do
          login_as_admin_and_visit spree.new_admin_order_payment_path order

          fill_in "payment_amount", with: order.total.to_s
          fill_in_card_details_in_backoffice
          click_button "Update"

          expect(page).to have_link "StripeSCA"
          expect(page).to have_content "AUTHORIZATION REQUIRED"
          expect(OrderPaymentFinder.new(order.reload).last_payment.state).to eq "requires_authorization"
        end
      end
    end

    context "for an order in payment state" do
      let!(:order) { create(:order_with_line_items, distributor: create(:enterprise)) }

      before do
        stub_payment_intents_post_request order: order, stripe_account_header: true
        stub_successful_capture_request order: order

        break unless order.next! while !order.payment?
      end

      it "adds a payment with state complete" do
        login_as_admin_and_visit spree.new_admin_order_payment_path order

        fill_in "payment_amount", with: order.total.to_s
        fill_in_card_details_in_backoffice
        click_button "Update"

        expect(page).to have_link "StripeSCA"
        expect(OrderPaymentFinder.new(order.reload).last_payment.state).to eq "completed"
      end
    end
  end

  context "with a payment using a StripeSCA payment method" do
    before do
      order.update payments: []
      order.payments << create(:payment, payment_method: stripe_payment_method, order: order)
    end

    it "renders the payment details" do
      login_as_admin_and_visit spree.admin_order_payments_path order

      page.click_link("StripeSCA")
      expect(page).to have_content order.payments.last.source.last_digits
    end

    context "with a deleted credit card" do
      before do
        order.payments.last.update source: nil
      end

      it "renders the payment details" do
        login_as_admin_and_visit spree.admin_order_payments_path order

        page.click_link("StripeSCA")
        expect(page).to have_content order.payments.last.amount
      end
    end

    context "that is completed" do
      let(:payment) { OrderPaymentFinder.new(order.reload).last_payment }

      before do
        payment.update response_code: "pi_123", amount: order.total, state: "completed"
        stub_payment_intent_get_request response: { intent_status: "succeeded" }, stripe_account_header: false
        stub_refund_request
      end

      it "allows to refund the payment" do
        login_as_admin_and_visit spree.admin_order_payments_path order

        expect(page).to have_link "StripeSCA"
        expect(page).to have_content "COMPLETED"

        page.find('a.icon-void').click

        expect(page).to have_content "VOID"
        expect(payment.reload.state).to eq "void"
      end
    end
  end
end
