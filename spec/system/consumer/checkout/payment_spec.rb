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

  let!(:payment_with_fee) {
    create(:payment_method, distributors: [distributor],
                            name: "Payment with Fee", description: "Payment with fee",
                            calculator: Calculator::FlatRate.new(preferred_amount: 1.23))
  }

  before do
    add_enterprise_fee enterprise_fee
    set_order order

    distributor.shipping_methods.push(free_shipping_with_required_address)
  end

  context "as a logged in user" do
    let(:user) { create(:user) }

    before do
      login_as(user)
      visit checkout_path
    end

    context "payment step" do
      let(:order) { create(:order_ready_for_payment, distributor:) }

      context "with one payment method, with a fee" do
        it "preselect the payment method if only one is available" do
          visit checkout_step_path(:payment)

          expect(page).to have_title "Checkout Payment - Open Food Network"
          expect(page).to have_checked_field "Payment with Fee"
          expect(page).to have_content "Payment with Fee $1.23"
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

      describe "vouchers", feature: :vouchers do
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

              within '#voucher-section' do
                expect(page).to have_button("Apply", disabled: true)
                expect(page).to have_field "Enter voucher code" # Currently no confirmation msg
              end
            end

            it "removes voucher" do
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
        let!(:tagged_customer) { create(:customer, user:, enterprise: distributor) }
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
  end

  def add_voucher_to_order(voucher, order)
    voucher.create_adjustment(voucher.code, order)
    VoucherAdjustmentsService.new(order).update
    order.update_totals_and_states
  end
end
