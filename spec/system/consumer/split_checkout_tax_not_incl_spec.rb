# frozen_string_literal: true

require "system_helper"

describe "As a consumer, I want to see adjustment breakdown" do
  include ShopWorkflow
  include SplitCheckoutHelper
  include CheckoutRequestsHelper
  include FileHelper
  include AuthenticationHelper
  include WebHelper

  let!(:state) { create(:state, name: "Victoria") }
  let!(:zone) { create(:zone_with_state_member, default_tax: false, member: state) }
  let!(:address_within_zone) { create(:address, state: state) }
  let!(:address_outside_zone) {
    create(:address, state: create(:state, name: "Timbuktu", country: state.country))
  }
  let(:user_within_zone) {
    create(:user, bill_address: address_within_zone,
                  ship_address: address_within_zone)
  }
  let(:user_outside_zone) {
    create(:user, bill_address: address_outside_zone,
                  ship_address: address_outside_zone)
  }
  let!(:tax_category) { create(:tax_category, name: "Veggies", is_default: false) }
  let!(:tax_rate) {
    create(:tax_rate, name: "Tax rate - included or not", amount: 0.13,
                      zone: zone, tax_category: tax_category, included_in_price: false)
  }
  let(:distributor) { create(:distributor_enterprise, charges_sales_tax: true) }
  let(:supplier) { create(:supplier_enterprise) }
  let(:product_with_tax) {
    create(:product, supplier: supplier, price: 10, tax_category_id: tax_category.id)
  }
  let(:variant_with_tax) { product_with_tax.variants.first }
  let(:order_cycle) {
    create(:simple_order_cycle, suppliers: [supplier], distributors: [distributor],
                                coordinator: distributor, variants: [variant_with_tax])
  }
  let!(:free_shipping) {
    create(:shipping_method, distributors: [distributor], require_ship_address: true,
                             name: "Delivery", description: "Payment without fee",
                             calculator: Calculator::FlatRate.new(preferred_amount: 0.00))
  }
  let!(:free_payment) {
    create(:payment_method, distributors: [distributor],
                            name: "Payment without Fee", description: "Payment without fee",
                            calculator: Calculator::FlatRate.new(preferred_amount: 0.00))
  }
  let(:order_within_zone) {
    create(:order, order_cycle: order_cycle, distributor: distributor, user: user_within_zone,
                   bill_address: address_within_zone, ship_address: address_within_zone,
                   state: "cart", line_items: [create(:line_item, variant: variant_with_tax)])
  }
  let(:order_outside_zone) {
    create(:order, order_cycle: order_cycle, distributor: distributor, user: user_outside_zone,
                   bill_address: address_outside_zone, ship_address: address_outside_zone,
                   state: "cart", line_items: [create(:line_item, variant: variant_with_tax)])
  }

  before do
    # assures tax is charged in dependence of shipping address
    Spree::Config.set(tax_using_ship_address: true)
    Flipper.enable :vouchers
  end

  describe "a not-included tax" do
    before do
      zone.update!(default_tax: false)
      tax_rate.update!(included_in_price: false)
      Spree::Config[:products_require_tax_category] = false
    end

    context "as superadmin" do
      before { login_as_admin }

      it "checks all tax settings are correctly set" do
        visit "/admin/zones/#{zone.id}/edit"
        expect(page).to have_field('zone_default_tax', checked: false)

        visit "/admin/tax_settings/edit"
        expect(page).to have_field('preferences_products_require_tax_category', checked: false)

        visit "/admin/tax_categories/#{tax_category.id}/edit"
        expect(page).to have_field('tax_category_is_default', checked: false)

        visit "/admin/tax_rates/#{tax_rate.id}/edit"
        expect(page).to have_field('tax_rate_included_in_price', checked: false)
      end
    end

    describe "for a customer with shipping address within the tax zone" do
      before do
        set_order order_within_zone
        login_as(user_within_zone)
      end

      it "will be charged tax on the order" do
        visit checkout_step_path(:details)

        choose "Delivery"

        click_button "Next - Payment method"

        # DB checks
        expect(order_within_zone.reload.additional_tax_total).to eq(1.3)

        click_on "Next - Order summary"
        click_on "Complete order"

        # UI checks
        expect(page).to have_content("Confirmed")
        expect(page).to have_selector('#order_total', text: with_currency(11.30))
        expect(page).to have_selector('#tax-row', text: with_currency(1.30))
      end

      context "when using a voucher" do
        let!(:voucher) do
          create(:voucher_flat_rate, code: 'some_code', enterprise: distributor, amount: 10)
        end

        it "will include a tax included amount on the voucher adjustment" do
          visit checkout_step_path(:details)

          choose "Delivery"

          click_button "Next - Payment method"

          # add Voucher
          fill_in "Enter voucher code", with: "some_code"
          click_button("Apply")
          expect(page).to have_selector ".voucher-added"

          click_on "Next - Order summary"
          click_on "Complete order"

          # UI checks
          expect(page).to have_content("Confirmed")
          expect(page).to have_selector('#order_total', text: with_currency(1.30))
          expect(page).to have_selector('#tax-row', text: with_currency(1.30))

          # Voucher
          within "#line-items" do
            expect(page).to have_content(voucher.code)
            expect(page).to have_content(with_currency(-8.85))

            expect(page).to have_content("Tax #{voucher.code}")
            expect(page).to have_content(with_currency(-1.15))
          end

          # DB check
          assert_db_voucher_adjustment(-8.85, -1.15)
        end

        describe "moving between summary to summary via edit cart" do
          let!(:voucher) do
            create(:voucher_percentage_rate, code: 'good_code', enterprise: distributor, amount: 20)
          end

          it "recalculate the tax component properly" do
            visit checkout_step_path(:details)
            proceed_to_payment

            # add Voucher
            fill_in "Enter voucher code", with: voucher.code
            click_button("Apply")

            proceed_to_summary
            assert_db_voucher_adjustment(-2.00, -0.26)

            # Click on edit link
            within "div", text: /Order details/ do
              # It's a bit brittle, but the scoping doesn't seem to work
              all(".summary-edit").last.click
            end

            # Update quantity
            within ".cart-item-quantity" do
              input = find(".line_item_quantity")
              input.send_keys :up
            end

            click_button("Update")

            # Check adjustment has been recalculated
            assert_db_voucher_adjustment(-4.00, -0.52)

            within "#cart-container" do
              click_link("Checkout")
            end

            # Go back to payment step
            proceed_to_payment

            # Check voucher is still there
            expect(page).to have_content("20.00% Voucher")

            # Go to summary
            proceed_to_summary

            # Check voucher value
            within ".summary-right" do
              expect(page).to have_content "good_code"
              expect(page).to have_content "-4"
              expect(page).to have_content "Tax good_code"
              expect(page).to have_content "-0.52"
            end

            # Check adjustment has been recalculated, we are not expecting any changes here
            assert_db_voucher_adjustment(-4.00, -0.52)
          end
        end
      end
    end

    describe "for a customer with shipping address outside the tax zone" do
      before do
        set_order order_outside_zone
        login_as(user_outside_zone)
      end

      it "will not be charged tax on the order" do
        visit checkout_step_path(:details)

        choose "Delivery"

        click_button "Next - Payment method"
        click_on "Next - Order summary"
        click_on "Complete order"

        # DB checks
        order_outside_zone.reload
        expect(order_outside_zone.included_tax_total).to eq(0.0)
        expect(order_outside_zone.additional_tax_total).to eq(0.0)

        # UI checks
        expect(page).to have_content("Confirmed")
        expect(page).to have_selector('#order_total', text: with_currency(10.00))
        expect(page).not_to have_content("includes tax")
      end

      # reproducing bug #9153
      context "changing the address on the /details step" do
        before do
          visit checkout_step_path(:details)
          choose "Delivery"

          click_button "Next - Payment method"
          click_on "Next - Order summary"

          expect(page).to have_selector('#order_total', text: with_currency(10.00))

          # customer goes back from Summary to Details step, to change Delivery
          click_on "Your details"
        end

        it "should re-calculate the tax accordingly" do
          select "Victoria", from: "order_bill_address_attributes_state_id"

          # it should not be necessary to save as new default bill address
          check "order_save_bill_address"
          check "ship_address_same_as_billing"

          choose "Delivery"
          click_button "Next - Payment method"

          click_on "Next - Order summary"

          # Summary step should reflect changes
          expect(page).to have_selector('#order_total', text: with_currency(11.30))
          expect(page).to have_selector('#tax-row', text: with_currency(1.30))

          click_on "Complete order"

          # DB checks
          order_outside_zone.reload
          expect(order_outside_zone.included_tax_total).to eq(0.0)
          expect(order_outside_zone.additional_tax_total).to eq(1.3)

          # UI checks - Order confirmation page should reflect changes
          expect(page).to have_content("Confirmed")
          expect(page).to have_selector('#order_total', text: with_currency(11.30))
          expect(page).to have_selector('#tax-row', text: with_currency(1.30))
        end
      end
    end
  end

  private

  def assert_db_voucher_adjustment(amount, tax_amount)
    adjustment = order_within_zone.voucher_adjustments.first
    tax_adjustment = order_within_zone.voucher_adjustments.second
    expect(adjustment.amount.to_f).to eq(amount)
    expect(tax_adjustment.amount.to_f).to eq(tax_amount)
  end
end
