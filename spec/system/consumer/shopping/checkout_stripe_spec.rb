# frozen_string_literal: true

require 'spec_helper'

feature "Check out with Stripe", js: true do
  include AuthenticationHelper
  include ShopWorkflow
  include CheckoutRequestsHelper
  include StripeHelper
  include StripeStubs

  let(:distributor) { create(:distributor_enterprise) }
  let!(:order_cycle) {
    create(:simple_order_cycle, distributors: [distributor], variants: [variant])
  }
  let(:product) { create(:product, price: 10) }
  let(:variant) { product.variants.first }
  let(:order) {
    create(:order, order_cycle: order_cycle, distributor: distributor, bill_address_id: nil,
                   ship_address_id: nil)
  }

  let(:shipping_with_fee) {
    create(:shipping_method, require_ship_address: false, name: "Donkeys",
                             calculator: Calculator::FlatRate.new(preferred_amount: 4.56))
  }
  let(:free_shipping) { create(:shipping_method) }
  let!(:check_with_fee) {
    create(:payment_method, distributors: [distributor],
                            calculator: Calculator::FlatRate.new(preferred_amount: 5.67))
  }

  before do
    setup_stripe
    set_order order
    add_product_to_cart order, product
    distributor.shipping_methods << [shipping_with_fee, free_shipping]
  end

  context 'login in as user' do
    let(:user) { create(:user) }

    before do
      login_as(user)
    end

    context "with Stripe Connect" do
      let!(:stripe_pm) do
        create(:stripe_connect_payment_method, distributors: [distributor])
      end

      let!(:saved_card) do
        create(:credit_card,
               user_id: user.id,
               month: "01",
               year: "2025",
               cc_type: "visa",
               number: "1111111111111111",
               payment_method_id: stripe_pm.id,
               gateway_customer_profile_id: "i_am_saved")
      end

      let!(:stripe_account) {
        create(:stripe_account, enterprise_id: distributor.id, stripe_user_id: 'some_id')
      }

      let(:response_mock) { { id: "ch_1234", object: "charge", amount: 2000 } }

      around do |example|
        original_stripe_connect_enabled = Spree::Config[:stripe_connect_enabled]
        example.run
        Spree::Config.set(stripe_connect_enabled: original_stripe_connect_enabled)
      end

      before do
        stub_request(:post, "https://api.stripe.com/v1/charges")
          .with(basic_auth: ["sk_test_12345", ""])
          .to_return(status: 200, body: JSON.generate(response_mock))

        visit checkout_path
        fill_out_form(shipping_with_fee.name, stripe_pm.name, save_default_addresses: false)
      end

      it "allows use of a saved card" do
        # shows the saved credit card dropdown
        expect(page).to have_content I18n.t("spree.checkout.payment.stripe.used_saved_card")

        # default card is selected, form element is not shown
        expect(page).to have_no_selector "#card-element.StripeElement"
        expect(page).to have_select 'selected_card', selected: "Visa x-1111 Exp:01/2025"

        # allows checkout
        place_order
        expect(page).to have_content "Your order has been processed successfully"
      end
    end
  end

  describe "using Stripe SCA" do
    let!(:stripe_account) { create(:stripe_account, enterprise: distributor) }
    let!(:stripe_sca_payment_method) {
      create(:stripe_sca_payment_method, distributors: [distributor])
    }
    let!(:shipping_method) { create(:shipping_method) }
    let(:error_message) { "Card was declined: insufficient funds." }

    before do
      stub_payment_intent_get_request
      stub_payment_methods_post_request
    end

    context "with guest checkout" do
      before do
        stub_retrieve_payment_method_request("pm_123")
        stub_list_customers_request(email: order.user.email, response: {})
        stub_get_customer_payment_methods_request(customer: "cus_A456", response: {})
      end

      context "when the card is accepted" do
        before do
          stub_payment_intents_post_request order: order
          stub_successful_capture_request order: order
        end

        it "completes checkout successfully" do
          checkout_with_stripe

          expect(page).to have_content "Confirmed"
          expect(order.reload.completed?).to eq true
          expect(order.payments.first.state).to eq "completed"
        end
      end

      context "when the card is rejected" do
        before do
          stub_payment_intents_post_request order: order
          stub_failed_capture_request order: order, response: { message: error_message }
        end

        it "shows an error message from the Stripe response" do
          checkout_with_stripe

          expect(page).to have_content error_message
          expect(order.reload.state).to eq "cart"
          expect(order.payments.first.state).to eq "failed"
        end
      end

      context "when the card needs extra SCA authorization" do
        before do
          stripe_redirect_url = checkout_path(payment_intent: "pi_123")
          stub_payment_intents_post_request_with_redirect order: order,
                                                          redirect_url: stripe_redirect_url
        end

        describe "and the authorization succeeds" do
          before do
            stub_successful_capture_request order: order
          end

          it "completes checkout successfully" do
            checkout_with_stripe

            # We make stripe return stripe_redirect_url (which is already sending the user back to the checkout) as if the authorization was done
            # We can then control the actual authorization or failure of the payment through the mock stub_successful_capture_request

            expect(page).to have_content "Confirmed"
            expect(order.reload.completed?).to eq true
            expect(order.payments.first.state).to eq "completed"
          end
        end

        describe "and the authorization fails" do
          before do
            stub_failed_capture_request order: order, response: { message: error_message }
          end

          it "shows an error message from the Stripe response" do
            checkout_with_stripe

            # We make stripe return stripe_redirect_url (which is already sending the user back to the checkout) as if the authorization was done
            # We can then control the actual authorization or failure of the payment through the mock stub_failed_capture_request

            expect(page).to have_content error_message
            expect(order.reload.state).to eq "cart"
            expect(order.payments.first.state).to eq "failed"
          end
        end
      end

      context "with multiple payment attempts; one failed and one succeeded" do
        before do
          stub_payment_intents_post_request order: order
        end

        it "records failed payment attempt and allows order completion" do
          # First payment attempt is rejected
          stub_failed_capture_request(order: order, response: { message: error_message })
          checkout_with_stripe
          expect(page).to have_content error_message

          expect(order.reload.payments.count).to eq 1
          expect(order.state).to eq "cart"
          expect(order.payments.first.state).to eq "failed"

          # Second payment attempt is accepted
          stub_successful_capture_request order: order
          place_order
          expect(page).to have_content "Confirmed"

          expect(order.reload.payments.count).to eq 2
          expect(order.state).to eq "complete"
          expect(order.payments.last.state).to eq "completed"
        end
      end
    end

    context "with a logged in user" do
      let(:user) { order.user }

      before do
        login_as user
      end

      context "saving a card and re-using it" do
        before do
          stub_retrieve_payment_method_request("pm_123")
          stub_list_customers_request(email: order.user.email, response: {})
          stub_get_customer_payment_methods_request(customer: "cus_A456", response: {})
          stub_get_customer_payment_methods_request(customer: "cus_A123", response: {})
          stub_payment_methods_post_request request: { payment_method: "pm_123", customer: "cus_A123" },
                                            response: { pm_id: "pm_123" }
          stub_add_metadata_request(payment_method: "pm_123", response: {})
          stub_payment_intents_post_request order: order
          stub_successful_capture_request order: order
          stub_customers_post_request email: "test@test.com" # First checkout with default details
          stub_customers_post_request email: user.email # Second checkout with saved user details
          stub_payment_method_attach_request
        end

        it "allows saving a card and re-using it" do
          checkout_with_stripe guest_checkout: false, remember_card: true

          expect(page).to have_content "Confirmed"
          expect(order.reload.completed?).to eq true
          expect(order.payments.first.state).to eq "completed"

          # Verify card has been saved with correct stripe IDs
          user_credit_card = order.reload.user.credit_cards.first
          expect(user_credit_card.gateway_payment_profile_id).to eq "pm_123"
          expect(user_credit_card.gateway_customer_profile_id).to eq "cus_A123"

          # Prepare a second order
          new_order = create(:order, user: user, order_cycle: order_cycle,
                                     distributor: distributor, bill_address_id: nil, ship_address_id: nil)
          set_order(new_order)
          add_product_to_cart(new_order, product, quantity: 10)
          stub_payment_intents_post_request order: new_order
          stub_successful_capture_request order: new_order

          # Checkout with saved card
          visit checkout_path
          choose free_shipping.name
          choose stripe_sca_payment_method.name
          expect(page).to have_content "Use a saved card"
          expect(page).to have_select 'selected_card', selected: "Visa x-4242 Exp:10/2050"
          place_order
        end
      end
    end
  end
end
