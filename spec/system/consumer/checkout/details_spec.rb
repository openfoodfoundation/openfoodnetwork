# frozen_string_literal: true

require "system_helper"

describe "As a consumer, I want to checkout my order" do
  include ShopWorkflow
  include CheckoutHelper
  include FileHelper
  include StripeHelper
  include StripeStubs
  include PaypalHelper
  include AuthenticationHelper

  let!(:zone) { create(:zone_with_member) }
  let(:supplier) { create(:supplier_enterprise) }
  let(:distributor) { create(:distributor_enterprise, charges_sales_tax: true) }
  let(:product) {
    create(:taxed_product, supplier:, price: 10, zone:, tax_rate_amount: 0.1)
  }
  let(:variant) { product.variants.first }
  let!(:order_cycle) {
    create(:simple_order_cycle, suppliers: [supplier], distributors: [distributor],
                                coordinator: create(:distributor_enterprise), variants: [variant])
  }
  let(:order) {
    create(:order, order_cycle:, distributor:, bill_address_id: nil,
                   ship_address_id: nil, state: "cart",
                   line_items: [create(:line_item, variant:)])
  }

  let(:fee_tax_rate) { create(:tax_rate, amount: 0.10, zone:, included_in_price: true) }
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
  let(:shipping_tax_rate) { create(:tax_rate, amount: 0.25, zone:, included_in_price: true) }
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
     free_shipping_without_required_address]
  }

  before do
    add_enterprise_fee enterprise_fee
    set_order order

    distributor.shipping_methods.push(shipping_methods)
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
        it "display the checkbox about shipping address same as billing address " \
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
          # Check for the right title first. This is a random place here but
          # we don't have a standard success checkout flow case to add this to.
          expect(page).to have_title "Checkout Details - Open Food Network"

          visit checkout_path
          expect(page).to have_select(
            "order_bill_address_attributes_state_id", selected: "Testville"
          )
          expect(page).to have_field "order_bill_address_attributes_zipcode", with: "TST01"
        end
      end
    end
  end
end
