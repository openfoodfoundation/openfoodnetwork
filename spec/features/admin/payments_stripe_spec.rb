# frozen_string_literal: true

require 'spec_helper'

feature '
    As an hub manager
    I want to make Stripe payments
' do
  include AuthenticationHelper
  include StripeHelper

  let!(:order) { create(:completed_order_with_fees) }
  let!(:stripe_payment_method) do
    create(:stripe_sca_payment_method, distributors: [order.distributor])
  end

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
        order.payments.last.update source: nil
      end

      it "renders the payment details" do
        login_as_admin_and_visit spree.admin_order_payments_path order

        page.click_link("StripeSCA")
        expect(page).to have_content order.payments.last.amount
      end
    end
  end

  context "making a new Stripe payment", js: true do
    let!(:stripe_account) do
      create(:stripe_account, enterprise: order.distributor, stripe_user_id: "abc123")
    end

    before do
      stub_payment_methods_post_request
      stub_payment_intent_get_request
    end

    context "for a complete order" do
      context "with a card that succceeds on card registration" do
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
                                                          redirect_url: "www.dummy.org"
        end

        it "fails to add a payment due to card error" do
          login_as_admin_and_visit spree.new_admin_order_payment_path order

          fill_in "payment_amount", with: order.total.to_s
          fill_in_card_details_in_backoffice
          click_button "Update"

          expect(page).to have_link "StripeSCA"
          expect(page).to have_content "PROCESSING"
          expect(OrderPaymentFinder.new(order.reload).last_payment.state).to eq "processing"
        end
      end
    end

    context "for an order in payment state" do
      let!(:order) { create(:order_with_line_items, distributor: create(:enterprise)) }

      before do
        stub_payment_intents_post_request order: order, stripe_account_header: true
        stub_successful_capture_request order: order

        while !order.payment? do break unless order.next! end
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
end
