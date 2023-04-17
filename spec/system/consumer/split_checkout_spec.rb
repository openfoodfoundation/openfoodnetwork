# frozen_string_literal: true

require "system_helper"

describe "As a consumer, I want to checkout my order" do
  include ShopWorkflow
  include SplitCheckoutHelper
  include FileHelper
  include StripeHelper
  include StripeStubs
  include PaypalHelper
  include AuthenticationHelper

  let!(:zone) { create(:zone_with_member) }
  let(:supplier) { create(:supplier_enterprise) }
  let(:distributor) { create(:distributor_enterprise, charges_sales_tax: true) }
  let(:product) {
    create(:taxed_product, supplier: supplier, price: 10, zone: zone, tax_rate_amount: 0.1)
  }
  let(:variant) { product.variants.first }
  let!(:order_cycle) {
    create(:simple_order_cycle, suppliers: [supplier], distributors: [distributor],
                                coordinator: create(:distributor_enterprise), variants: [variant])
  }
  let(:order) {
    create(:order, order_cycle: order_cycle, distributor: distributor, bill_address_id: nil,
                   ship_address_id: nil, state: "cart",
                   line_items: [create(:line_item, variant: variant)])
  }

  let(:fee_tax_rate) { create(:tax_rate, amount: 0.10, zone: zone, included_in_price: true) }
  let(:fee_tax_category) { create(:tax_category, tax_rates: [fee_tax_rate]) }
  let(:enterprise_fee) { create(:enterprise_fee, amount: 1.23, tax_category: fee_tax_category) }

  let(:free_shipping_with_required_address) {
    create(:shipping_method, require_ship_address: true,
                             name: "A Free Shipping with required address")
  }
  let(:free_shipping) {
    create(:shipping_method, require_ship_address: false, name: "free Shipping",
                             description: "yellow",
                             calculator: Calculator::FlatRate.new(preferred_amount: 0.00))
  }
  let(:shipping_tax_rate) { create(:tax_rate, amount: 0.25, zone: zone, included_in_price: true) }
  let(:shipping_tax_category) { create(:tax_category, tax_rates: [shipping_tax_rate]) }
  let(:shipping_with_fee) {
    create(:shipping_method, require_ship_address: true, tax_category: shipping_tax_category,
                             name: "Shipping with Fee", description: "blue",
                             calculator: Calculator::FlatRate.new(preferred_amount: 4.56))
  }
  let(:free_shipping_without_required_address) {
    create(:shipping_method, require_ship_address: false,
                             name: "Z Free Shipping without required address")
  }
  let(:tagged_shipping) {
    create(:shipping_method, require_ship_address: false, name: "Local", tag_list: "local")
  }
  let!(:payment_with_fee) {
    create(:payment_method, distributors: [distributor],
                            name: "Payment with Fee", description: "Payment with fee",
                            calculator: Calculator::FlatRate.new(preferred_amount: 1.23))
  }
  let(:shipping_backoffice_only) {
    create(:shipping_method, require_ship_address: true, name: "Shipping Backoffice Only",
                             display_on: "back_end")
  }
  let(:shipping_methods) {
    [free_shipping_with_required_address, free_shipping, shipping_with_fee,
     free_shipping_without_required_address, tagged_shipping]
  }

  before do
    Flipper.enable(:split_checkout)

    add_enterprise_fee enterprise_fee
    set_order order

    distributor.shipping_methods.push(shipping_methods)
  end

  context "guest checkout when distributor doesn't allow guest orders" do
    before do
      distributor.update_columns allow_guest_orders: false
      visit checkout_step_path(:details)
    end

    it "should display the split checkout login page" do
      expect(page).to have_content("Ok, ready to checkout?")
      expect(page).to have_content("Login")
      expect(page).to have_no_content("Checkout as guest")
    end

    it "should show the login modal when clicking the login button" do
      click_on "Login"
      expect(page).to have_selector ".login-modal"
    end
  end

  shared_examples "when I have an out of stock product in my cart" do
    before do
      variant.update!(on_demand: false, on_hand: 0)
    end

    it "returns me to the cart with an error message" do
      visit checkout_path

      expect(page).not_to have_selector 'closing', text: "Checkout now"
      expect(page).to have_selector 'closing', text: "Your shopping cart"
      expect(page).to have_content "An item in your cart has become unavailable"
      expect(page).to have_content "Update"
    end
  end

  context "as a guest user" do
    before do
      visit checkout_path
    end

    context "actually user has an account and wants to login" do
      let(:user) { create(:user) }

      it "should redirect to '/checkout/details' when user submit the login form" do
        expect(page).to have_content("Ok, ready to checkout?")

        click_on "Login"
        within ".login-modal" do
          fill_in_and_submit_login_form(user)
        end

        expect_logged_in
        expect(page).not_to have_selector ".login-modal"
        expect_to_be_on_first_step
      end
    end

    it "should display the split checkout login/guest form" do
      expect(page).to have_content distributor.name
      expect(page).to have_content("Ok, ready to checkout?")
      expect(page).to have_content("Login")
      expect(page).to have_content("Checkout as guest")
    end

    it "should display the split checkout details page" do
      click_on "Checkout as guest"
      expect(page).to have_content distributor.name
      expect_to_be_on_first_step
    end

    context "when no shipping methods are available" do
      before do
        shipping_methods.each { |sm| sm.update(tag_list: "hidden") }
      end

      it "should display an error message" do
        create(:filter_shipping_methods_tag_rule,
               enterprise: distributor,
               is_default: true,
               preferred_shipping_method_tags: "hidden",
               preferred_matched_shipping_methods_visibility: 'hidden')

        visit checkout_path
        expect(page).to have_content(
          "Checkout is not possible due to absence of shipping options. "\
          "Please contact the shop owner."
        )
      end
    end

    it "should display error when fields are empty" do
      click_on "Checkout as guest"
      click_button "Next - Payment method"
      expect(page).to have_content("Saving failed, please update the highlighted fields")
      expect(page).to have_css 'span.field_with_errors label', count: 6
      expect(page).to have_css 'span.field_with_errors input', count: 6
      expect(page).to have_css 'span.formError', count: 7
    end

    it "should validate once each needed field is filled" do
      click_on "Checkout as guest"
      fill_in "First Name", with: "Jane"
      fill_in "Last Name", with: "Doe"
      fill_in "Phone number", with: "07987654321"
      fill_in "Address (Street + House Number)", with: "Flat 1 Elm apartments"
      fill_in "City", with: "London"
      fill_in "Postcode", with: "SW1A 1AA"
      choose free_shipping.name

      click_button "Next - Payment method"
      expect(page).to have_button("Next - Order summary")
    end

    context "on the 'details' step" do
      before do
        visit checkout_step_path(:details)
        click_on "Checkout as guest"
      end

      context "should show proper list of errors" do
        before do
          click_button "Next - Payment method"
          expect(page).to have_content "Saving failed, please update the highlighted fields."
        end

        it "should not display any shipping errors messages when shipping method is not selected" do
          expect(page).not_to have_content "Shipping address line 1 can't be blank"
          expect(page).not_to have_content "Shipping address suburb 1 can't be blank"
          expect(page).not_to have_content "Shipping address postcode can't be blank"
        end

        it "should not display bill address phone number error message" do
          expect(page).not_to have_content "Bill address phone can't be blank"
          expect(page).to have_content "Customer phone can't be blank"
        end

        context "with no email filled in" do
          before do
            fill_in "Email", with: ""
            click_button "Next - Payment method"
          end

          it "should display error message in the right order" do
            expect(page).to have_content(
              "Customer E-Mail can't be blank, Customer E-Mail is invalid, Customer phone can't "\
              "be blank, Billing address first name can't be blank, Billing address last name "\
              "can't be blank, Billing address (Street + House number) can't be blank, Billing "\
              "address city can't be blank, Billing address postcode can't be blank, and "\
              "Shipping method Select a shipping method"
            )
          end
        end
      end

      it "should allow visit '/checkout/details'" do
        expect(page).to have_current_path("/checkout/details")
      end

      it 'does not show the save as default bill address checkbox' do
        expect(page).not_to have_content "Save as default billing address"
      end

      it 'does not show the save as default ship address checkbox' do
        choose free_shipping_with_required_address.name
        uncheck "ship_address_same_as_billing"
        expect(page).not_to have_content "Save as default shipping address"
      end

      it 'display shipping methods alphabetically' do
        shipping_methods = page.all(:field, "shipping_method_id")
          .map { |field| field.sibling("label") }.map(&:text)
        expect(shipping_methods).to eq [
          "A Free Shipping with required address", "free Shipping",
          "Local", "Shipping with Fee", "Z Free Shipping without required address"
        ]
      end

      it_behaves_like "when I have an out of stock product in my cart"
    end

    context "on the 'payment' step" do
      before do
        order.update(state: "payment")
        visit checkout_step_path(:payment)
      end

      it "should allow visit '/checkout/payment'" do
        expect(page).to have_current_path("/checkout/payment")
      end

      it_behaves_like "when I have an out of stock product in my cart"
    end

    describe "hidding a shipping method" do
      let(:user) { create(:user) }
      let(:customer) { create(:customer, user: user, enterprise: distributor) }

      it "shows shipping methods allowed by the rule" do
        visit checkout_path
        click_on "Checkout as guest"

        # No rules in effect
        expect(page).to have_content free_shipping.name
        expect(page).to have_content shipping_with_fee.name
        expect(page).to have_content free_shipping_without_required_address.name
        expect(page).to have_content tagged_shipping.name

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

        # Default rule in effect, disallows access to 'Local'
        expect(page).to have_content free_shipping.name
        expect(page).to have_content shipping_with_fee.name
        expect(page).to have_content free_shipping_without_required_address.name
        expect(page).not_to have_content tagged_shipping.name

        login_as(user)
        visit checkout_path

        # Default rule in still effect, disallows access to 'Local'
        expect(page).to have_content free_shipping.name
        expect(page).to have_content shipping_with_fee.name
        expect(page).to have_content free_shipping_without_required_address.name
        expect(page).not_to have_content tagged_shipping.name

        customer.update_attribute(:tag_list, "local")
        visit checkout_path

        # #local Customer can access 'Local' shipping method
        expect(page).to have_content free_shipping.name
        expect(page).to have_content shipping_with_fee.name
        expect(page).to have_content free_shipping_without_required_address.name
        expect(page).to have_content tagged_shipping.name
      end
    end
  end

  context "as a logged in user" do
    let(:user) { create(:user) }

    before do
      login_as(user)
      visit checkout_path
    end

    context "when no selecting a shipping method" do
      before do
        fill_out_details
        fill_out_billing_address
      end

      it "errors is shown to the user when submitting the form" do
        click_button "Next - Payment method"
        expect(page).to have_content "Select a shipping method"
      end
    end

    context "details step" do
      context "when form is submitted but invalid" do
        it "display the checkbox about shipping address same as billing address "\
           "when selecting a shipping method that requires ship address" do
          choose free_shipping_with_required_address.name
          check "Shipping address same as billing address?"
          expect(page).to have_content "Save as default shipping address"

          click_button "Next - Payment method"

          expect(page).to have_content "Saving failed, please update the highlighted fields."
          expect(page).to have_content "Save as default shipping address"
          expect(page).to have_checked_field "Shipping address same as billing address?"
        end
      end

      describe "filling out order details" do
        before do
          fill_out_details
          fill_out_billing_address
          order.update(user_id: user.id)
        end

        context "billing address" do
          describe "checking the default address box" do
            before do
              check "order_save_bill_address"
              choose free_shipping.name
            end

            it "creates a new default bill address" do
              expect {
                proceed_to_payment
                order.reload
                user.reload
              }.to change {
                order.bill_address&.address1
              }.from(nil).to("Rue de la Vie, 77")
                .and change {
                       order.customer&.bill_address&.address1
                     }.from(nil).to("Rue de la Vie, 77")
                .and change {
                       order.bill_address&.address1
                     }
                .from(nil).to("Rue de la Vie, 77")
            end
          end

          describe "unchecking the default address box" do
            before do
              uncheck "order_save_bill_address"
              choose free_shipping.name
            end

            context "proceeding to payment" do
              before do
                expect {
                  proceed_to_payment
                }.to_not change {
                  user.reload.bill_address
                }
              end

              it "updates the bill address of the order and customer" do
                expect(order.reload.bill_address.address1).to eq "Rue de la Vie, 77"
                expect(order.customer.bill_address.address1).to eq "Rue de la Vie, 77"
              end
            end
          end
        end

        context "shipping address" do
          describe "checking the default address box" do
            before do
              choose free_shipping_with_required_address.name
              uncheck "ship_address_same_as_billing"
              fill_out_shipping_address
              check "order_save_ship_address"
            end

            context "proceeding to payment" do
              it "creates a new default ship address" do
                expect {
                  proceed_to_payment
                  order.reload
                  user.reload
                }.to change {
                  order.ship_address&.address1
                }.from(nil).to("Rue de la Vie, 66")
                  .and change {
                         order.customer&.ship_address&.address1
                       }.from(nil).to("Rue de la Vie, 66")
                  .and change {
                         order.ship_address&.address1
                       }
                  .from(nil).to("Rue de la Vie, 66")
              end
            end
          end

          describe "unchecking the default address box" do
            before do
              choose free_shipping_with_required_address.name
              uncheck "ship_address_same_as_billing"
              fill_out_shipping_address
              uncheck "order_save_ship_address"
            end

            context "proceeding to payment" do
              before do
                expect {
                  proceed_to_payment
                }.to_not change {
                           user.reload.ship_address
                         }
              end

              it "updates the ship address of the order and customer" do
                expect(order.reload.ship_address.address1).to eq "Rue de la Vie, 66"
                expect(order.customer.ship_address.address1).to eq "Rue de la Vie, 66"
              end
            end
          end
        end

        describe "selecting a pick-up shipping method and submiting the form" do
          before do
            choose free_shipping.name
          end

          it "redirects the user to the Payment Method step" do
            fill_notes("SpEcIaL NoTeS")
            proceed_to_payment
          end

          context 'when the user has no shipping address' do
            before do
              # Hack so we can have "Shipping address same as billing address?" unticked
              choose free_shipping_with_required_address.name
              uncheck "Shipping address same as billing address?"
              choose free_shipping_without_required_address.name
            end

            it "redirects the user to the Payment Method step" do
              proceed_to_payment
            end
          end
        end

        describe "selecting a delivery method with a shipping fee" do
          before do
            choose shipping_with_fee.name
          end

          context "with same shipping and billing address" do
            before do
              check "ship_address_same_as_billing"
            end

            it "displays the shipping fee" do
              expect(page).to have_content("#{shipping_with_fee.name} " + with_currency(4.56).to_s)
            end

            it "does not display the shipping address form" do
              expect(page).not_to have_field "order_ship_address_attributes_address1"
            end

            it "redirects the user to the Payment Method step, when submiting the form" do
              proceed_to_payment
              # asserts whether shipping and billing addresses are the same
              ship_add_id = order.reload.ship_address_id
              bill_add_id = order.reload.bill_address_id
              expect(Spree::Address.where(id: bill_add_id).pluck(:address1) ==
                Spree::Address.where(id: ship_add_id).pluck(:address1)).to be true
            end

            context "with a shipping fee" do
              before do
                proceed_to_payment
                click_button "Next - Order summary"
              end

              shared_examples "displays the shipping fee" do |checkout_page|
                it "on the #{checkout_page} page" do
                  expect(page).to have_content("Shipping #{with_currency(4.56)}")

                  if checkout_page.eql?("order confirmation")
                    expect(page).to have_content "Your order has been processed successfully"
                  end
                end
              end

              it_behaves_like "displays the shipping fee", "order summary"

              context "after completing the order" do
                before do
                  click_on "Complete order"
                end
                it_behaves_like "displays the shipping fee", "order confirmation"
              end
            end
          end

          context "with different shipping and billing address" do
            before do
              uncheck "ship_address_same_as_billing"
            end
            it "displays the shipping address form and the option to save it as default" do
              expect(page).to have_field "order_ship_address_attributes_address1"
            end

            it "displays error messages when submitting incomplete billing address" do
              click_button "Next - Payment method"
              within "checkout" do
                expect(page).to have_field("Address", with: "")
                expect(page).to have_field("City", with: "")
                expect(page).to have_field("Postcode", with: "")
                expect(page).to have_content("can't be blank", count: 3)
              end
              within ".flash[type='error']" do
                expect(page).to have_content "Saving failed, please update the highlighted fields."
                expect(page).to have_content("can't be blank", count: 3)
              end
            end

            it "fills in shipping details and redirects the user to the Payment Method step,
            when submiting the form" do
              fill_out_shipping_address
              fill_notes("SpEcIaL NoTeS")
              proceed_to_payment
              # asserts whether shipping and billing addresses are the same
              ship_add_id = Spree::Order.first.ship_address_id
              bill_add_id = Spree::Order.first.bill_address_id
              expect(Spree::Address.where(id: bill_add_id).pluck(:address1) ==
               Spree::Address.where(id: ship_add_id).pluck(:address1)).to be false
            end
          end
        end

        describe "pre-selecting a shipping method" do
          it "preselect a shipping method if only one is available" do
            order.distributor.update! shipping_methods: [free_shipping, shipping_backoffice_only]

            visit checkout_step_path(:details)

            expect(page).to have_checked_field "shipping_method_#{free_shipping.id}"
          end

          it "don't preselect a shipping method if more than one is available" do
            order.distributor.update! shipping_methods: [free_shipping, shipping_with_fee]

            visit checkout_step_path(:details)

            expect(page).to have_field "shipping_method_#{free_shipping.id}", checked: false
            expect(page).to have_field "shipping_method_#{shipping_with_fee.id}", checked: false
          end
        end
      end

      describe "not filling out delivery details" do
        before do
          fill_in "Email", with: ""
        end
        it "should display error when fields are empty" do
          click_button "Next - Payment method"
          within "checkout" do
            expect(page).to have_field("First Name", with: "")
            expect(page).to have_field("Last Name", with: "")
            expect(page).to have_field("Email", with: "")
            expect(page).to have_content("is invalid")
            expect(page).to have_field("Phone number", with: "")
            expect(page).to have_field("Address", with: "")
            expect(page).to have_field("City", with: "")
            expect(page).to have_field("Postcode", with: "")
            expect(page).to have_content("can't be blank", count: 7)
            expect(page).to have_content("Select a shipping method")
          end
          within ".flash[type='error']" do
            expect(page).to have_content("Saving failed, please update the highlighted fields")
            expect(page).to have_content("can't be blank", count: 7)
            expect(page).to have_content("is invalid", count: 1)
          end
        end
      end

      context "with a saved address" do
        let!(:address_state) do
          create(:state, name: "Testville", abbr: "TST", country: DefaultCountry.country )
        end
        let(:saved_address) do
          create(:bill_address, state: address_state, zipcode: "TST01" )
        end

        before do
          user.update_columns bill_address_id: saved_address.id
        end

        it "pre-fills address details" do
          visit checkout_path
          expect(page).to have_select(
            "order_bill_address_attributes_state_id", selected: "Testville"
          )
          expect(page).to have_field "order_bill_address_attributes_zipcode", with: "TST01"
        end
      end
    end

    context "payment step" do
      let(:order) { create(:order_ready_for_payment, distributor: distributor) }

      context "with one payment method, with a fee" do
        before do
          visit checkout_step_path(:payment)
        end
        it "preselect the payment method if only one is available" do
          expect(page).to have_checked_field "payment_method_#{payment_with_fee.id}"
        end
        it "displays the transaction fee" do
          expect(page).to have_content("#{payment_with_fee.name} " + with_currency(1.23).to_s)
        end
      end

      context "with a transaction fee" do
        before do
          click_button "Next - Order summary"
        end

        shared_examples "displays the transaction fee" do |checkout_page|
          it "on the #{checkout_page} page" do
            expect(page).to have_content("Transaction fee #{with_currency(1.23)}")

            if checkout_page.eql?("order confirmation")
              expect(page).to have_content "Your order has been processed successfully"
            end
          end
        end

        it_behaves_like "displays the transaction fee", "order summary"

        context "after completing the order" do
          before do
            click_on "Complete order"
          end
          it_behaves_like "displays the transaction fee", "order confirmation"
        end
      end

      context "with more than one payment method" do
        let!(:payment_method) { create(:payment_method, distributors: [distributor]) }

        before do
          visit checkout_step_path(:payment)
        end

        it "don't preselect the payment method if more than one is available" do
          expect(page).to have_field "payment_method_#{payment_with_fee.id}", checked: false
          expect(page).to have_field "payment_method_#{payment_method.id}", checked: false
        end

        it "requires choosing a payment method" do
          click_on "Next - Order summary"
          expect(page).to have_content "Select a payment method"
        end
      end

      describe "vouchers" do
        context "with no voucher available" do
          before do
            visit checkout_step_path(:payment)
          end

          it "doesn't show voucher input" do
            expect(page).not_to have_content "Apply voucher"
          end
        end

        context "with voucher available" do
          let!(:voucher) { Voucher.create(code: 'some_code', enterprise: distributor) }

          before do
            visit checkout_step_path(:payment)
          end

          it "shows voucher input" do
            expect(page).to have_content "Apply voucher"
          end

          describe "adding voucher to the order" do
            shared_examples "adding voucher to the order" do
              before do
                fill_in "Enter voucher code", with: voucher.code
                click_button("Apply")
              end

              it "adds a voucher to the order" do
                expect(page).to have_content("$10.00 Voucher")
                expect(order.reload.voucher_adjustments.length).to eq(1)
              end
            end

            it_behaves_like "adding voucher to the order"

            context "when voucher covers more then the order total" do
              before do
                order.total = 6
                order.save!
              end

              it_behaves_like "adding voucher to the order"

              it "shows a warning message" do
                fill_in "Enter voucher code", with: voucher.code
                click_button("Apply")

                expect(page).to have_content(
                  "Your voucher value is more than your order. " \
                  "By using this voucher you are forfeiting the remaining value."
                )
              end
            end

            context "voucher doesn't exist" do
              it "show an error" do
                fill_in "Enter voucher code", with: "non_code"
                click_button("Apply")

                expect(page).to have_content("Voucher Not found")
              end
            end
          end

          describe "removing voucher from order" do
            before do
              voucher.create_adjustment(voucher.code, order)
              # Reload the page so we pickup the voucher
              visit checkout_step_path(:payment)
            end

            it "removes voucher" do
              accept_confirm "Are you sure you want to remove the voucher ?" do
                click_on "Remove code"
              end

              within '.voucher' do
                expect(page).to have_button("Apply")
              end
              expect(order.voucher_adjustments.length).to eq(0)
            end
          end
        end
      end

      describe "choosing" do
        shared_examples "different payment methods" do |pay_method|
          context "checking out with #{pay_method}", if: pay_method.eql?("Stripe SCA") == false do
            before do
              visit checkout_step_path(:payment)
            end

            it "proceeds to the summary step and completes the order" do
              choose pay_method.to_s
              proceed_to_summary

              place_order
              expect(page).to have_content "Paying via: #{pay_method}"
              expect(order.reload.state).to eq "complete"
            end
          end

          context "for Stripe SCA", if: pay_method.eql?("Stripe SCA") do
            around do |example|
              with_stripe_setup { example.run }
            end

            before do
              stripe_enable
              visit checkout_step_path(:payment)
            end

            it "selects Stripe SCA and proceeds to the summary step" do
              choose pay_method.to_s
              fill_out_card_details
              click_on "Next - Order summary"
              proceed_to_summary
            end
          end
        end

        describe "shared examples" do
          let!(:cash) { create(:payment_method, distributors: [distributor], name: "Cash") }

          context "Cash" do
            it_behaves_like "different payment methods", "Cash"
          end

          context "Paypal" do
            let!(:paypal) do
              Spree::Gateway::PayPalExpress.create!(
                name: "Paypal",
                environment: "test",
                distributor_ids: [distributor.id]
              )
            end

            before do
              stub_paypal_response(
                success: true,
                redirect: payment_gateways_confirm_paypal_path(
                  payment_method_id: paypal.id, token: "t123", PayerID: 'p123'
                )
              )
              stub_paypal_confirm
            end

            it_behaves_like "different payment methods", "Paypal"
          end

          context "Stripe SCA" do
            let!(:stripe_account) { create(:stripe_account, enterprise: distributor) }
            let!(:stripe_sca_payment_method) {
              create(:stripe_sca_payment_method, distributors: [distributor], name: "Stripe SCA")
            }

            it_behaves_like "different payment methods", "Stripe SCA"
          end
        end
      end

      describe "hiding a payment method with a default rule" do
        let!(:tagged_customer) { create(:customer, user: user, enterprise: distributor) }
        let!(:hidden_method) {
          create(:payment_method, distributors: [distributor], name: "Hidden", tag_list: "hide_pm")
        }
        before do
          create(:filter_payment_methods_tag_rule,
                 enterprise: distributor,
                 is_default: true,
                 preferred_payment_method_tags: "hide_pm",
                 preferred_matched_payment_methods_visibility: 'hidden')
          visit checkout_step_path(:payment)
        end

        context "with no exceptions set to a customer" do
          it "hides the payment method" do
            expect(page).not_to have_content hidden_method.name
          end
        end

        context "with an exception set to a customer" do
          before do
            create(:filter_payment_methods_tag_rule,
                   enterprise: distributor,
                   preferred_customer_tags: "show_pm",
                   preferred_payment_method_tags: "hide_pm",
                   preferred_matched_payment_methods_visibility: 'visible')
            tagged_customer.update_attribute(:tag_list, "show_pm")
            visit checkout_step_path(:payment)
          end

          it "displays the payment method" do
            expect(page).to have_content hidden_method.name
          end
        end
      end
    end

    context "summary step" do
      let(:order) {
        create(:order_ready_for_confirmation, distributor: distributor)
      }

      describe "with an order with special instructions" do
        before do
          order.update_attribute(:special_instructions, "Please deliver on Tuesday")
          visit checkout_step_path(:summary)
        end

        it "displays the special instructions" do
          expect(page).to have_content "Please deliver on Tuesday"
        end
      end

      describe "completing the checkout" do
        it "keeps the distributor selected for the current user after completion" do
          visit checkout_step_path(:summary)

          expect(page).to have_content "Shopping @ #{distributor.name}"

          place_order

          expect(page).to have_content "Back To Store"
          expect(order.reload.state).to eq "complete"

          expect(page).to have_content "Shopping @ #{distributor.name}"
        end
      end

      describe "navigation available" do
        it "redirect to Payment method step by clicking on 'Payment method' link" do
          visit checkout_step_path(:summary)

          click_link "Payment method"

          expect(page).to have_content("You can review and confirm your order in the next step "\
                                       "which includes the final costs.")
        end
      end

      describe "terms and conditions" do
        let(:customer) { create(:customer, enterprise: order.distributor, user: user) }
        let(:tos_url) { "https://example.org/tos" }
        let(:system_terms_path) { Rails.root.join("public/Terms-of-service.pdf") }
        let(:shop_terms_path) { Rails.root.join("public/Terms-of-ServiceUK.pdf") }
        let(:system_terms) {
          Rack::Test::UploadedFile.new(system_terms_path, "application/pdf")
        }
        let(:shop_terms) {
          Rack::Test::UploadedFile.new(shop_terms_path, "application/pdf")
        }

        context "when none are required" do
          it "doesn't show checkbox or links" do
            visit checkout_step_path(:summary)

            within "#checkout" do
              expect(page).to_not have_field "order_accept_terms"
              expect(page).to_not have_link "Terms and Conditions"
              expect(page).to_not have_link "Terms of service"
            end
          end
        end

        context "when distributor has T&Cs" do
          before do
            order.distributor.update!(terms_and_conditions: shop_terms)
          end

          describe "when customer has not accepted T&Cs before" do
            it "shows a link to the T&Cs and disables checkout button until terms are accepted" do
              visit checkout_step_path(:summary)
              expect(page).to have_link "Terms and Conditions", href: /#{shop_terms_path.basename}$/
              expect(page).to have_field "order_accept_terms", checked: false
            end
          end

          describe "when customer has already accepted T&Cs before" do
            before do
              customer.update terms_and_conditions_accepted_at: Time.zone.now
            end

            it "enables checkout button (because T&Cs are accepted by default)" do
              visit checkout_step_path(:summary)
              expect(page).to have_field "order_accept_terms", checked: true
            end

            describe "but afterwards the enterprise has uploaded a new T&Cs file" do
              before { order.distributor.update!(terms_and_conditions: shop_terms) }

              it "disables checkout button until terms are accepted" do
                visit checkout_step_path(:summary)
                expect(page).to have_field "order_accept_terms", checked: false
              end
            end
          end
        end

        context "when the platform's terms of service have to be accepted" do
          before do
            allow(Spree::Config).to receive(:shoppers_require_tos).and_return(true)
            allow(Spree::Config).to receive(:footer_tos_url).and_return(tos_url)
          end

          it "shows the terms which need to be accepted" do
            visit checkout_step_path(:summary)

            expect(page).to have_link "Terms of service", href: tos_url
            expect(find_link("Terms of service")[:target]).to eq "_blank"
            expect(page).to have_field "order_accept_terms", checked: false
          end

          context "when the terms have been accepted in the past" do
            

            context "with a dedicated ToS file" do
              before do
                TermsOfServiceFile.create!(
                  attachment: system_terms,
                  updated_at: 1.day.ago,
                )
                customer.update(terms_and_conditions_accepted_at: Time.zone.now)
              end

              it "remembers the selection" do
                visit checkout_step_path(:summary)

                expect(page).to have_link("Terms of service", href: /Terms-of-service.pdf/)
                expect(page).to have_field "order_accept_terms", checked: true
              end
            end

            context "with the default ToS file" do
              before do
                customer.update(terms_and_conditions_accepted_at: Time.zone.now)
              end

              it "remembers the selection" do
                pending "#10675"

                visit checkout_step_path(:summary)

                expect(page).to have_link("Terms of service", href: tos_url)
                expect(page).to have_field "order_accept_terms", checked: true
              end
            end
          end
        end

        context "when the seller's terms and the platform's terms have to be accepted" do
          before do
            order.distributor.update!(terms_and_conditions: shop_terms)

            allow(Spree::Config).to receive(:shoppers_require_tos).and_return(true)
            allow(Spree::Config).to receive(:footer_tos_url).and_return(tos_url)
          end

          it "shows links to both terms and all need accepting" do
            visit checkout_step_path(:summary)

            expect(page).to have_link "Terms and Conditions", href: /#{shop_terms_path.basename}$/
            expect(page).to have_link "Terms of service", href: tos_url
            expect(page).to have_field "order_accept_terms", checked: false
          end
        end
      end

      context "handle the navigation when the order is ready for confirmation" do
        it "redirect to summary step" do
          visit "/checkout"

          expect(page).to have_current_path checkout_step_path(:summary)
        end

        it "handle the navigation between each step by clicking tabs/buttons to submit the form" do
          visit checkout_step_path(:summary)

          click_on "Your details"

          expect(page).to have_current_path checkout_step_path(:details)

          click_on "Next - Payment method"

          expect(page).to have_current_path checkout_step_path(:payment)
        end
      end

      describe "order state" do
        before do
          visit checkout_step_path(:summary)
        end

        it "emptying the cart changes the order state back to address" do
          visit main_app.cart_path
          expect {
            find('#clear_cart_link').click
            expect(page).to have_current_path enterprise_shop_path(distributor)
          }.to change { order.reload.state }.from("confirmation").to("address")
        end
      end

      describe "vouchers" do
        let(:voucher) { Voucher.create(code: 'some_code', enterprise: distributor) }

        before do
          # Add voucher to the order
          voucher.create_adjustment(voucher.code, order)
          # Update order so voucher adjustment is properly taken into account
          order.update_order!

          visit checkout_step_path(:summary)
        end

        it "shows the applied voucher" do
          within ".summary-right" do
            expect(page).to have_content "some_code"
          end
        end
      end
    end

    context "with previous open orders" do
      let(:order) {
        create(:order_ready_for_confirmation, distributor: distributor,
                                              order_cycle: order_cycle, user_id: user.id)
      }
      let!(:prev_order) {
        create(:completed_order_with_totals,
               order_cycle: order_cycle, distributor: distributor, user_id: order.user_id)
      }

      context "when distributor allows order changes" do
        before do
          order.distributor.allow_order_changes = true
          order.distributor.save
          visit checkout_step_path(:summary)
        end

        it "informs about previous orders" do
          expect(page).to have_content("You have an order for this order cycle already.")
        end

        it "show a link to /cart#bought-products page" do
          expect(page).to have_link("cart", href: "/cart#bought-products")
          click_on "cart"
          expect(page).to have_text(
            "#{prev_order.line_items.length} "\
            "additional items already confirmed for this order cycle"
          )
        end
      end

      it "don't display any message if distributor don't allow order changes" do
        order.distributor.allow_order_changes = false
        order.distributor.save
        visit checkout_step_path(:summary)

        expect(page).to_not have_content("You have an order for this order cycle already.")
      end
    end
  end
end
