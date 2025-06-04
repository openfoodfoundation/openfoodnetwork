# frozen_string_literal: true

require 'system_helper'

RSpec.describe '
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

  context "making a new Stripe payment" do
    around do |example|
      with_stripe_setup { example.run }
    end

    before do
      stub_payment_methods_post_request
      stub_payment_intent_get_request
      stub_retrieve_payment_method_request("pm_123")
      stub_list_customers_request(email: order.user.email, response: {})
      stub_get_customer_payment_methods_request(customer: "cus_A456", response: {})
    end

    context "for a complete order" do
      context "with a card that succeeds on card registration" do
        before { stub_payment_intents_post_request order:, stripe_account_header: true }

        context "and succeeds on payment capture" do
          before { stub_successful_capture_request order: }

          it "adds a payment with state complete" do
            login_as_admin
            visit spree.new_admin_order_payment_path order

            fill_in "payment_amount", with: order.total.to_s
            fill_in_card_details_in_backoffice
            click_button "Update"

            expect(page).to have_link "StripeSCA"
            last_payment_state = Orders::FindPaymentService.new(order.reload).last_payment.state
            expect(last_payment_state).to eq 'completed'
          end
        end

        context "but fails on payment capture" do
          let(:error_message) { "Card was declined: insufficient funds." }

          before { stub_failed_capture_request order:, response: { message: error_message } }

          it "fails to add a payment due to card error" do
            login_as_admin
            visit spree.new_admin_order_payment_path order

            fill_in "payment_amount", with: order.total.to_s
            fill_in_card_details_in_backoffice
            click_button "Update"

            expect(page).to have_link "StripeSCA"
            expect(page).to have_content "FAILED"
            expect(Orders::FindPaymentService.new(order.reload).last_payment.state).to eq "failed"
          end
        end
      end

      context "with a card that fails on registration because it requires(redirects) extra auth" do
        before do
          stub_payment_intents_post_request_with_redirect order:,
                                                          redirect_url: "https://www.stripe.com/authorize"
        end

        it "adds the payment and it is in the requires_authorization state" do
          login_as_admin
          visit spree.new_admin_order_payment_path order

          fill_in "payment_amount", with: order.total.to_s
          fill_in_card_details_in_backoffice
          click_button "Update"

          expect(page).to have_link "StripeSCA"
          expect(page).to have_content "AUTHORIZATION REQUIRED"
          expect(Orders::FindPaymentService.new(order.reload).last_payment.state)
            .to eq "requires_authorization"
        end
      end
    end

    context "for an order in payment state" do
      let!(:order) { create(:order_with_line_items, distributor: create(:enterprise)) }

      before do
        stub_payment_intents_post_request order:, stripe_account_header: true
        stub_successful_capture_request(order:)

        Orders::WorkflowService.new(order).advance_to_payment
      end

      it "adds a payment with state complete" do
        login_as_admin
        visit spree.new_admin_order_payment_path order

        fill_in "payment_amount", with: order.total.to_s
        fill_in_card_details_in_backoffice
        click_button "Update"

        expect(page).to have_link "StripeSCA"
        expect(Orders::FindPaymentService.new(order.reload).last_payment.state).to eq "completed"
      end
    end
  end

  context "with a payment using a StripeSCA payment method" do
    before do
      order.update payments: []
      order.payments << create(:payment, payment_method: stripe_payment_method, order:)
    end

    it "renders the payment details" do
      login_as_admin
      visit spree.admin_order_payments_path order

      page.click_link("StripeSCA")
      expect(page).to have_content order.payments.last.source.last_digits
    end

    context "with a deleted credit card" do
      before do
        order.payments.last.update source: nil
      end

      it "renders the payment details" do
        login_as_admin
        visit spree.admin_order_payments_path order

        page.click_link("StripeSCA")
        expect(page).to have_content order.payments.last.amount
      end
    end

    context "that is completed", :vcr, :stripe_version do
      let(:payment) do
        create(
          :payment,
          order:,
          amount: order.total,
          payment_method: stripe_payment_method,
          source: credit_card,
          response_code: payment_intent.id,
          state: "completed"
        )
      end

      let(:connected_account) do
        Stripe::Account.create({
                                 type: 'standard',
                                 country: 'AU',
                                 email: 'lettuce.producer@example.com'
                               })
      end
      let(:stripe_test_account) { connected_account.id }
      # Stripe testing card:
      #     https://stripe.com/docs/testing?testing-method=payment-methods
      let(:pm_card) { Stripe::PaymentMethod.retrieve('pm_card_mastercard') }
      let(:credit_card) { create(:credit_card, gateway_payment_profile_id: pm_card.id) }
      let(:payment_intent) do
        Stripe::PaymentIntent.create(
          {
            amount: (order.total * 100).to_i, # given in AUD cents
            currency: 'aud', # AUD to match order currency
            payment_method: 'pm_card_mastercard',
            payment_method_types: ['card'],
            capture_method: 'automatic',
            confirm: true
          },
          stripe_account: stripe_test_account
        )
      end

      before do
        stripe_account.update!(stripe_user_id: stripe_test_account)

        order.update payments: []
        order.payments << payment
      end

      after do
        Stripe::Account.delete(connected_account.id)
      end

      it "allows to refund the payment" do
        login_as_admin
        visit spree.admin_order_payments_path order

        expect(page).to have_link "StripeSCA"
        expect(page).to have_content "COMPLETED"

        page.find('a.icon-void').click

        expect(page).to have_content "VOID", wait: 4
        expect(payment.reload.state).to eq "void"
      end
    end
  end
end
