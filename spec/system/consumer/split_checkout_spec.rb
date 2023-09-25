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
        before { Flipper.enable :vouchers }

        context "with no voucher available" do
          before do
            visit checkout_step_path(:payment)
          end

          it "doesn't show voucher input" do
            expect(page).not_to have_content "Apply voucher"
          end
        end

        context "with voucher available" do
          let!(:voucher) do
            create(:voucher_flat_rate, code: 'some_code', enterprise: distributor, amount: 15)
          end

          describe "adding voucher to the order" do
            before do
              visit checkout_step_path(:payment)
            end

            it "adds a voucher to the order" do
              apply_voucher "some_code"

              expect(page).to have_content "$15.00 Voucher"
              expect(order.reload.voucher_adjustments.length).to eq(1)
            end

            context "when voucher covers more then the order total" do
              before do
                order.total = 6
                order.save!
              end

              it "shows a warning message and doesn't require payment" do
                apply_voucher "some_code"

                expect(page).to have_content "$15.00 Voucher"
                expect(page).to have_content(
                  "Note: if your order total is less than your voucher " \
                  "you may not be able to spend the remaining value."
                )

                expect(page).to have_content "No payment required"
                click_button "Next - Order summary"
                # Expect to be on the Order Summary page
                expect(page).to have_content "Delivery details"
              end
            end

            context "voucher doesn't exist" do
              it "show an error" do
                fill_in "Enter voucher code", with: "non_code"
                click_button("Apply")

                expect(page).to have_content("Voucher code Not found")
              end
            end
          end

          describe "removing voucher from order" do
            before do
              add_voucher_to_order(voucher, order)

              visit checkout_step_path(:payment)

              accept_confirm "Are you sure you want to remove the voucher?" do
                click_on "Remove code"
              end
            end

            it "removes voucher" do
              within '#voucher-section' do
                expect(page).to have_button("Apply", disabled: true)
                expect(page).to have_field "Enter voucher code" # Currently no confirmation msg
              end

              expect(page).not_to have_content "No payment required"
              expect(order.voucher_adjustments.length).to eq(0)
            end

            it "can re-enter a voucher" do
              apply_voucher "some_code"

              expect(page).to have_content("$15.00 Voucher")
              expect(order.reload.voucher_adjustments.length).to eq(1)

              expect(page).to have_content "No payment required"

              click_button "Next - Order summary"
              # Expect to be on the Order Summary page
              expect(page).to have_content "Delivery details"
            end

            it "can proceed with payment" do
              click_button "Next - Order summary"
              # Expect to be on the Order Summary page
              expect(page).to have_content "Delivery details"
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

      describe "display the delivery address and not the ship address" do
        let(:ship_address) { create(:address, :randomized) }
        let(:bill_address) { create(:address, :randomized) }

        before do
          order.update_attribute(:ship_address, ship_address)
          order.update_attribute(:bill_address, bill_address)
          visit checkout_step_path(:summary)
        end

        it "displays the ship address" do
          expect(page).to have_content "Delivery address"
          expect(page).to have_content order.ship_address.address1
          expect(page).to have_content order.ship_address.city
          expect(page).to have_content order.ship_address.zipcode
          expect(page).to have_content order.ship_address.phone
        end

        it "and not the billing address" do
          expect(page).not_to have_content order.bill_address.address1
          expect(page).not_to have_content order.bill_address.city
          expect(page).not_to have_content order.bill_address.zipcode
          expect(page).not_to have_content order.bill_address.phone
        end
      end

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

          expect(page).to have_content("You can review and confirm your order in the next step " \
                                       "which includes the final costs.")
        end
      end

      describe "terms and conditions" do
        let(:customer) { create(:customer, enterprise: order.distributor, user: user) }
        let(:tos_url) { "https://example.org/tos" }
        let(:system_terms_path) { Rails.public_path.join('Terms-of-service.pdf') }
        let(:shop_terms_path) { Rails.public_path.join('Terms-of-ServiceUK.pdf') }
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
          end

          let!(:tos) do
            TermsOfServiceFile.create!(attachment: system_terms)
          end

          it "shows the terms which need to be accepted" do
            visit checkout_step_path(:summary)

            expect(page).to have_link("Terms of service", href: /Terms-of-service.pdf/, count: 2)
            expect(find_link("Terms of service")[:target]).to eq "_blank"
            expect(page).to have_field "order_accept_terms", checked: false
          end

          context "when the terms have been accepted in the past" do
            context "with a dedicated ToS file" do
              before do
                tos.update!(
                  updated_at: 1.day.ago
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
          end

          let!(:tos) do
            TermsOfServiceFile.create!(attachment: system_terms)
          end

          it "shows links to both terms and all need accepting" do
            visit checkout_step_path(:summary)

            expect(page).to have_link "Terms and Conditions", href: /#{shop_terms_path.basename}$/
            expect(page).to have_link("Terms of service", href: /Terms-of-service.pdf/, count: 2)
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
        let(:voucher) do
          create(:voucher_flat_rate, code: 'some_code', enterprise: distributor, amount: 6)
        end

        before do
          add_voucher_to_order(voucher, order)
        end

        it "shows the applied voucher" do
          visit checkout_step_path(:summary)

          within ".summary-right" do
            expect(page).to have_content "some_code"
            expect(page).to have_content "-6"
          end
        end

        context "with voucher deactivated after being added to an order" do
          it "completes the order" do
            visit checkout_step_path(:summary)

            # Deactivate voucher
            voucher.destroy

            place_order

            expect(order.reload.state).to eq "complete"
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
            "#{prev_order.line_items.length} " \
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

  def add_voucher_to_order(voucher, order)
    voucher.create_adjustment(voucher.code, order)
    VoucherAdjustmentsService.new(order).update
    order.update_totals_and_states
  end
end
