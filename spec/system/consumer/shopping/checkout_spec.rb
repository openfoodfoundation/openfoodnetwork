# frozen_string_literal: true

require 'system_helper'

describe "As a consumer I want to check out my cart" do
  include AuthenticationHelper
  include ShopWorkflow
  include CheckoutRequestsHelper
  include FileHelper
  include WebHelper
  include UIComponentHelper

  let!(:zone) { create(:zone_with_member) }
  let(:distributor) { create(:distributor_enterprise, charges_sales_tax: true) }
  let(:supplier) { create(:supplier_enterprise) }
  let!(:order_cycle) {
    create(:simple_order_cycle, suppliers: [supplier], distributors: [distributor],
                                coordinator: create(:distributor_enterprise), variants: [variant])
  }
  let(:enterprise_fee) { create(:enterprise_fee, amount: 1.23, tax_category: fee_tax_category) }
  let(:fee_tax_rate) { create(:tax_rate, amount: 0.10, zone: zone, included_in_price: true) }
  let(:fee_tax_category) { create(:tax_category, tax_rates: [fee_tax_rate]) }
  let(:product) {
    create(:taxed_product, supplier: supplier, price: 10, zone: zone, tax_rate_amount: 0.1, included_in_price: true)
  }
  let(:variant) { product.variants.first }
  let(:order) {
    create(:order, order_cycle: order_cycle, distributor: distributor, bill_address_id: nil,
                   ship_address_id: nil)
  }
  let(:shipping_tax_rate) { create(:tax_rate, amount: 0.25, zone: zone, included_in_price: true) }
  let(:shipping_tax_category) { create(:tax_category, tax_rates: [shipping_tax_rate]) }

  let(:free_shipping) {
    create(:shipping_method, require_ship_address: true, name: "Frogs", description: "yellow",
                             calculator: Calculator::FlatRate.new(preferred_amount: 0.00))
  }
  let(:shipping_with_fee) {
    create(:shipping_method, require_ship_address: false, tax_category: shipping_tax_category,
                             name: "Donkeys", description: "blue",
                             calculator: Calculator::FlatRate.new(preferred_amount: 4.56))
  }
  let(:tagged_shipping) {
    create(:shipping_method, require_ship_address: false, name: "Local", tag_list: "local")
  }
  let!(:check_without_fee) {
    create(:payment_method, distributors: [distributor], name: "Roger rabbit",
                            type: "Spree::PaymentMethod::Check")
  }
  let!(:check_with_fee) {
    create(:payment_method, distributors: [distributor],
                            calculator: Calculator::FlatRate.new(preferred_amount: 5.67))
  }
  let!(:paypal) do
    Spree::Gateway::PayPalExpress.create!(name: "Paypal", environment: 'test',
                                          distributor_ids: [distributor.id]).tap do |pm|
      pm.preferred_login = 'devnull-facilitator_api1.rohanmitchell.com'
      pm.preferred_password = '1406163716'
      pm.preferred_signature = 'AFcWxV21C7fd0v3bYYYRCpSSRl31AaTntNJ-AjvUJkWf4dgJIvcLsf1V'
    end
  end

  before do
    add_enterprise_fee enterprise_fee
    set_order order
    add_product_to_cart order, product

    distributor.shipping_methods << free_shipping
    distributor.shipping_methods << shipping_with_fee
    distributor.shipping_methods << tagged_shipping
  end

  describe "when I have an out of stock product in my cart" do
    before do
      variant.on_demand = false
      variant.on_hand = 0
      variant.save!
    end

    it "returns me to the cart with an error message" do
      visit checkout_path

      expect(page).not_to have_selector 'closing', text: "Checkout now"
      expect(page).to have_selector 'closing', text: "Your shopping cart"
      expect(page).to have_content "An item in your cart has become unavailable"
    end
  end

  context 'login in as user' do
    let(:user) { create(:user) }
    let(:pdf_upload) {
      Rack::Test::UploadedFile.new(
        Rails.root.join("public/Terms-of-service.pdf"),
        "application/pdf"
      )
    }

    before do
      login_as(user)
    end

    context "with details filled out" do
      before do
        visit checkout_path
        fill_out_form(free_shipping.name, check_without_fee.name)
      end

      it "creates a new default billing address and shipping address" do
        expect(user.bill_address).to be_nil
        expect(user.ship_address).to be_nil

        expect(order.bill_address).to be_nil
        expect(order.ship_address).to be_nil

        place_order
        expect(page).to have_content "Your order has been processed successfully"

        expect(order.reload.bill_address.address1).to eq '123 Your Head'
        expect(order.reload.ship_address.address1).to eq '123 Your Head'

        expect(order.customer.bill_address.address1).to eq '123 Your Head'
        expect(order.customer.ship_address.address1).to eq '123 Your Head'

        expect(user.reload.bill_address.address1).to eq '123 Your Head'
        expect(user.reload.ship_address.address1).to eq '123 Your Head'
      end

      context "when the user and customer have existing default addresses" do
        let(:existing_address) { create(:address) }

        before do
          user.bill_address = existing_address
          user.ship_address = existing_address
        end

        it "updates billing address and shipping address" do
          expect(order.bill_address).to be_nil
          expect(order.ship_address).to be_nil

          place_order
          expect(page).to have_content "Your order has been processed successfully"

          expect(order.reload.bill_address.address1).to eq '123 Your Head'
          expect(order.reload.ship_address.address1).to eq '123 Your Head'

          expect(order.customer.bill_address.address1).to eq '123 Your Head'
          expect(order.customer.ship_address.address1).to eq '123 Your Head'

          expect(user.reload.bill_address.address1).to eq '123 Your Head'
          expect(user.reload.ship_address.address1).to eq '123 Your Head'
        end
      end

      it "shows only applicable content" do
        expect(page).to have_no_content("You have an order for this order cycle already.")

        expect(page).to have_no_link("Terms and Conditions")

        # We always have this link in the footer.
        within "#checkout_form" do
          expect(page).to have_no_link("Terms of service")
        end
      end
    end

    context "when distributor has T&Cs" do
      before do
        order.distributor.terms_and_conditions = pdf_upload
        order.distributor.save!
      end

      describe "when customer has not accepted T&Cs before" do
        it "shows a link to the T&Cs and disables checkout button until terms are accepted" do
          visit checkout_path

          expect(page).to have_link("Terms and Conditions")

          expect(page).to have_button("Place order now", disabled: true)

          check "accept_terms"
          expect(page).to have_button("Place order now", disabled: false)
        end
      end

      describe "when customer has already accepted T&Cs before" do
        before do
          customer = create(:customer, enterprise: order.distributor, user: user)
          customer.update terms_and_conditions_accepted_at: Time.zone.now
        end

        it "enables checkout button (because T&Cs are accepted by default)" do
          visit checkout_path
          expect(page).to have_button("Place order now", disabled: false)
        end

        describe "but afterwards the enterprise has uploaded a new T&Cs file" do
          before { order.distributor.terms_and_conditions.attach(pdf_upload) }

          it "disables checkout button until terms are accepted" do
            visit checkout_path
            expect(page).to have_button("Place order now", disabled: true)
          end
        end
      end
    end

    context "when the platform's terms of service have to be accepted" do
      let(:tos_url) { "https://example.org/tos" }

      before do
        allow(Spree::Config).to receive(:shoppers_require_tos).and_return(true)
        allow(Spree::Config).to receive(:footer_tos_url).and_return(tos_url)
      end

      it "shows the terms which need to be accepted" do
        visit checkout_path

        within "#checkout_form" do
          expect(page).to have_link("Terms of service", href: tos_url)
          expect(find_link("Terms of service")[:target]).to eq "_blank"
          expect(page).to have_button("Place order now", disabled: true)
        end

        check "accept_terms"
        expect(page).to have_button("Place order now", disabled: false)

        uncheck "accept_terms"
        expect(page).to have_button("Place order now", disabled: true)
      end

      context "when the terms have been accepted in the past" do
        before do
          TermsOfServiceFile.create!(
            attachment: pdf_upload,
            updated_at: 1.day.ago,
          )
          customer = create(:customer, enterprise: order.distributor, user: user)
          customer.update(terms_and_conditions_accepted_at: Time.zone.now)
        end

        it "remembers the acceptance" do
          visit checkout_path

          within "#checkout_form" do
            expect(page).to have_link("Terms of service")
            expect(page).to have_button("Place order now", disabled: false)
          end

          uncheck "accept_terms"
          expect(page).to have_button("Place order now", disabled: true)

          check "accept_terms"
          expect(page).to have_button("Place order now", disabled: false)
        end
      end
    end

    context "when the seller's terms and the platform's terms have to be accepted" do
      let(:tos_url) { "https://example.org/tos" }

      before do
        order.distributor.terms_and_conditions = pdf_upload
        order.distributor.save!

        allow(Spree::Config).to receive(:shoppers_require_tos).and_return(true)
        allow(Spree::Config).to receive(:footer_tos_url).and_return(tos_url)
      end

      it "shows links to both terms and all need accepting" do
        visit checkout_path

        within "#checkout_form" do
          expect(page).to have_link("Terms and Conditions")
          expect(page).to have_link("Terms of service", href: tos_url)
          expect(page).to have_button("Place order now", disabled: true)
        end

        # Both Ts&Cs and TOS appear in the one label for the one checkbox.
        check "accept_terms"
        expect(page).to have_button("Place order now", disabled: false)

        uncheck "accept_terms"
        expect(page).to have_button("Place order now", disabled: true)
      end
    end

    context "with previous orders" do
      let!(:prev_order) {
        create(:completed_order_with_totals, order_cycle: order_cycle, distributor: distributor,
                                             user: order.user)
      }

      before do
        order.distributor.allow_order_changes = true
        order.distributor.save
        visit checkout_path
      end

      it "informs about previous orders" do
        expect(page).to have_content("You have an order for this order cycle already.")
      end
    end

    context "when the user has a preset shipping and billing address" do
      before do
        user.bill_address = build(:address)
        user.ship_address = build(:address)
        user.save!
      end

      it "checks out successfully" do
        visit checkout_path

        expect(page).to have_content "Shipping info"
        find(:xpath, '//*[@id="shipping"]/ng-form/dd').click
        find("input[value='#{shipping_with_fee.id}'").click
        click_button "Next"
        expect(page).to have_content "Payment"
        find("input[value='#{check_without_fee.id}'").click

        perform_enqueued_jobs do
          place_order

          expect(page).to have_content "Your order has been processed successfully"

          expect(ActionMailer::Base.deliveries.first.subject).to match(/Order Confirmation/)
          expect(ActionMailer::Base.deliveries.second.subject).to match(/Order Confirmation/)
        end

        order = Spree::Order.complete.last
        expect(order.payment_state).to eq "balance_due"
        expect(order.shipment_state).to eq "pending"
      end
    end
  end

  context "guest checkout" do
    before do
      visit checkout_path
      checkout_as_guest
    end

    it "shows the current distributor" do
      visit checkout_path
      expect(page).to have_content distributor.name
    end

    it 'does not show the save as default address checkbox' do
      expect(page).not_to have_content "Save as default billing address"
      expect(page).not_to have_content "Save as default shipping address"
    end

    it "shows a breakdown of the order price" do
      choose shipping_with_fee.name

      expect(page).to have_selector 'orderdetails .cart-total', text: with_currency(11.23)
      expect(page).to have_selector 'orderdetails .shipping', text: with_currency(4.56)
      expect(page).to have_selector 'orderdetails .total', text: with_currency(15.79)

      # Tax should not be displayed in checkout, as the customer's choice of shipping method
      # affects the tax and we haven't written code to live-update the tax amount when they
      # make a change.
      expect(page).not_to have_content product.tax_category.name
    end

    it "shows all shipping methods in order by name" do
      within '#shipping' do
        expect(page).to have_selector "label", count: 4 # Three shipping methods + instructions label
        labels = page.all('label').map(&:text)
        expect(labels[0]).to start_with("Donkeys") # shipping_with_fee
        expect(labels[1]).to start_with("Frogs") # free_shipping
        expect(labels[2]).to start_with("Local") # tagged_shipping
      end
    end

    context "when shipping method requires an address" do
      before do
        choose free_shipping.name
      end
      it "shows ship address forms when 'same as billing address' is unchecked" do
        uncheck "Shipping address same as billing address?"
        expect(find("#ship_address > div.visible").visible?).to be true
      end
    end

    it "filters out 'Back office only' shipping methods" do
      expect(page).to have_content shipping_with_fee.name
      shipping_with_fee.update_attribute :display_on, 'back_end' # Back office only

      visit checkout_path
      checkout_as_guest
      expect(page).not_to have_content shipping_with_fee.name
    end

    context "using FilterShippingMethods" do
      let(:user) { create(:user) }
      let(:customer) { create(:customer, user: user, enterprise: distributor) }

      it "shows shipping methods allowed by the rule" do
        # No rules in effect
        expect(page).to have_content "Frogs"
        expect(page).to have_content "Donkeys"
        expect(page).to have_content "Local"

        create(:filter_shipping_methods_tag_rule,
               enterprise: distributor,
               preferred_customer_tags: "local",
               preferred_shipping_method_tags: "local",
               preferred_matched_shipping_methods_visibility: 'visible')
        create(:filter_shipping_methods_tag_rule,
               enterprise: distributor,
               is_default: true,
               preferred_shipping_method_tags: "local",
               preferred_matched_shipping_methods_visibility: 'hidden')
        visit checkout_path
        checkout_as_guest

        # Default rule in effect, disallows access to 'Local'
        expect(page).to have_content "Frogs"
        expect(page).to have_content "Donkeys"
        expect(page).not_to have_content "Local"

        login_as(user)
        visit checkout_path

        # Default rule in still effect, disallows access to 'Local'
        expect(page).to have_content "Frogs"
        expect(page).to have_content "Donkeys"
        expect(page).not_to have_content "Local"

        customer.update_attribute(:tag_list, "local")
        visit checkout_path

        # #local Customer can access 'Local' shipping method
        expect(page).to have_content "Frogs"
        expect(page).to have_content "Donkeys"
        expect(page).to have_content "Local"
      end
    end

    it "shows all available payment methods" do
      expect(page).to have_content check_without_fee.name
      expect(page).to have_content check_with_fee.name
      expect(page).to have_content paypal.name
    end

    describe "purchasing" do
      it "takes us to the order confirmation page when we submit a complete form" do
        fill_out_details
        fill_out_billing_address

        within "#shipping" do
          choose shipping_with_fee.name
          fill_in 'Any comments or special instructions?', with: "SpEcIaL NoTeS"
        end

        within "#payment" do
          choose check_without_fee.name
        end

        expect do
          place_order
          expect(page).to have_content "Your order has been processed successfully"
        end.to have_enqueued_mail(Spree::OrderMailer, :confirm_email_for_customer)

        # And the order's special instructions should be set
        order = Spree::Order.complete.last
        expect(order.special_instructions).to eq "SpEcIaL NoTeS"

        # Shipment and payments states should be set
        expect(order.payment_state).to eq "balance_due"
        expect(order.shipment_state).to eq "pending"

        # And the Spree tax summary should not be displayed
        expect(page).not_to have_content product.tax_category.name

        # And the total tax for the order, including shipping and fee tax, should be displayed
        # product tax    ($10.00 @ 10% = $0.91)
        # + fee tax      ($ 1.23 @ 10% = $0.11)
        # + shipping tax ($ 4.56 @ 25% = $0.91)
        #                              = $1.93
        expect(page).to have_content '(includes tax)'
        expect(page).to have_content with_currency(1.93)
        expect(page).to have_content 'Back To Store'
      end

      context "with basic details filled" do
        before do
          choose free_shipping.name
          choose check_without_fee.name
          fill_out_details
          fill_out_billing_address
          check "Shipping address same as billing address?"
        end

        it "takes us to the order confirmation page when submitted with 'same as billing address' checked" do
          place_order
          expect(page).to have_content "Your order has been processed successfully"

          order = Spree::Order.complete.last
          expect(order.payment_state).to eq "balance_due"
          expect(order.shipment_state).to eq "pending"
        end

        it "takes us to the cart page with an error when a product becomes out of stock just before we purchase" do
          variant.on_demand = false
          variant.on_hand = 0
          variant.save!

          place_order

          expect(page).not_to have_content "Your order has been processed successfully"
          expect(page).to have_selector 'closing', text: "Your shopping cart"
          expect(page).to have_content "An item in your cart has become unavailable."
        end

        context "when we are charged a shipping fee" do
          before { choose shipping_with_fee.name }

          it "creates a payment for the full amount inclusive of shipping" do
            place_order
            expect(page).to have_content "Your order has been processed successfully"

            # There are two orders - our order and our new cart
            order = Spree::Order.complete.last
            expect(order.shipment_adjustments.first.amount).to eq(4.56)
            expect(order.payments.first.amount).to eq(10 + 1.23 + 4.56) # items + fees + shipping
            expect(order.payment_state).to eq "balance_due"
            expect(order.shipment_state).to eq "pending"
          end
        end

        context "when we are charged a payment method fee (transaction fee)" do
          it "creates a payment including the transaction fee" do
            # Selecting the transaction fee, it is displayed
            expect(page).to have_selector ".transaction-fee td", text: with_currency(0.00)
            expect(page).to have_selector ".total", text: with_currency(11.23)

            choose "#{check_with_fee.name} (#{with_currency(5.67)})"

            expect(page).to have_selector ".transaction-fee td", text: with_currency(5.67)
            expect(page).to have_selector ".total", text: with_currency(16.90)

            place_order
            expect(page).to have_content "Your order has been processed successfully"

            # There are two orders - our order and our new cart
            order = Spree::Order.complete.last
            expect(order.all_adjustments.payment_fee.first.amount).to eq 5.67
            expect(order.payments.first.amount).to eq(10 + 1.23 + 5.67) # items + fees + transaction
            expect(order.payment_state).to eq "balance_due"
            expect(order.shipment_state).to eq "pending"
          end
        end

        describe "credit card payments" do
          ["Spree::Gateway::Bogus", "Spree::Gateway::BogusSimple"].each do |gateway_type|
            context "with a credit card payment method using #{gateway_type}" do
              let!(:check_without_fee) {
                create(:payment_method, distributors: [distributor], name: "Roger rabbit",
                                        type: gateway_type)
              }

              it "takes us to the order confirmation page when submitted with a valid credit card" do
                fill_in 'Card Number', with: "4111111111111111"
                select 'February', from: 'secrets.card_month'
                select (Date.current.year + 1).to_s, from: 'secrets.card_year'
                fill_in 'Security Code', with: '123'

                place_order
                expect(page).to have_content "Your order has been processed successfully"

                # Order should have a payment with the correct amount
                order = Spree::Order.complete.last
                expect(order.payments.first.amount).to eq(11.23)
                expect(order.payment_state).to eq "paid"
                expect(order.shipment_state).to eq "ready"
              end

              it "shows the payment processing failed message when submitted with an invalid credit card" do
                fill_in 'Card Number', with: "9999999988887777"
                select 'February', from: 'secrets.card_month'
                select (Date.current.year + 1).to_s, from: 'secrets.card_year'
                fill_in 'Security Code', with: '123'

                place_order
                expect(page).to have_content 'Bogus Gateway: Forced failure'

                # Does not show duplicate shipping fee
                visit checkout_path
                expect(page).to have_selector "th", text: "Shipping", count: 1
              end
            end
          end
        end
      end
    end
  end
end
