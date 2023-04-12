# frozen_string_literal: true

require "system_helper"

describe "As a consumer, I want to see adjustment breakdown" do
  include ShopWorkflow
  include SplitCheckoutHelper
  include CheckoutRequestsHelper
  include FileHelper
  include AuthenticationHelper
  include WebHelper

  let!(:address_within_zone) { create(:address, state_id: Spree::State.first.id) }
  let!(:address_outside_zone) { create(:address, state_id: Spree::State.second.id) }
  let!(:user_within_zone) {
    create(:user, bill_address_id: address_within_zone.id,
                  ship_address_id: address_within_zone.id)
  }
  let!(:user_outside_zone) {
    create(:user, bill_address_id: address_outside_zone.id,
                  ship_address_id: address_outside_zone.id)
  }
  let!(:zone) { create(:zone_with_state_member, name: 'Victoria', default_tax: true) }
  let!(:tax_category) { create(:tax_category, name: "Veggies", is_default: "f") }
  let!(:tax_rate) {
    create(:tax_rate, name: "Tax rate - included or not", amount: 0.13,
                      zone_id: zone.id, tax_category_id: tax_category.id, included_in_price: true)
  }
  let(:distributor) { create(:distributor_enterprise, charges_sales_tax: true) }
  let(:supplier) { create(:supplier_enterprise) }
  let!(:product_with_tax) {
    create(:simple_product, supplier: supplier, price: 10, tax_category_id: tax_category.id)
  }
  let!(:variant_with_tax) { product_with_tax.variants.first }
  let!(:order_cycle) {
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
  let!(:order_within_zone) {
    create(:order, order_cycle: order_cycle, distributor: distributor, user: user_within_zone,
                   bill_address: address_within_zone, ship_address: address_within_zone,
                   state: "cart", line_items: [create(:line_item, variant: variant_with_tax)])
  }
  let!(:order_outside_zone) {
    create(:order, order_cycle: order_cycle, distributor: distributor, user: user_outside_zone,
                   bill_address: address_outside_zone, ship_address: address_outside_zone,
                   state: "cart", line_items: [create(:line_item, variant: variant_with_tax)])
  }

  before do
    # assures tax is charged in dependence of shipping address
    Spree::Config.set(tax_using_ship_address: true)
  end

  describe "an included tax" do
    context "as superadmin" do
      before { login_as_admin }

      it "checks all tax settings are correctly set" do
        visit "/admin/zones/#{zone.id}/edit"
        expect(page).to have_field('zone_default_tax', checked: true)

        visit "/admin/tax_settings/edit"
        expect(page).to have_field('preferences_products_require_tax_category', checked: false)

        visit "/admin/tax_categories/#{tax_category.id}/edit"
        expect(page).to have_field('tax_category_is_default', checked: false)

        visit "/admin/tax_rates/#{tax_rate.id}/edit"
        expect(page).to have_field('tax_rate_included_in_price', checked: true)
      end
    end

    describe "for a customer with shipping address within the tax zone" do
      context "on legacy checkout" do
        before do
          set_order order_within_zone
          login_as(user_within_zone)
        end

        it "will be charged tax on the order" do
          visit checkout_path

          find(:xpath, '//*[@id="shipping"]/ng-form/dd').click
          choose free_shipping.name.to_s

          within "#payment" do
            choose free_payment.name.to_s
          end

          click_on "Place order now"

          # UI checks
          expect(page).to have_selector('#order_total', text: with_currency(10.00))
          expect(page).to have_selector('#tax-row', text: with_currency(1.15))

          # DB checks
          assert_db_tax_incl
        end
      end

      context "on split-checkout" do
        before do
          Flipper.enable(:split_checkout)

          set_order order_within_zone
          login_as(user_within_zone)
        end

        it "will be charged tax on the order" do
          visit checkout_step_path(:details)

          choose "Delivery"

          click_button "Next - Payment method"
          click_on "Next - Order summary"
          click_on "Complete order"

          # UI checks
          expect(page).to have_content("Confirmed")
          expect(page).to have_selector('#order_total', text: with_currency(10.00))
          expect(page).to have_selector('#tax-row', text: with_currency(1.15))

          # DB checks
          assert_db_tax_incl
        end

        context "when using a voucher" do
          let!(:voucher) { Voucher.create(code: 'some_code', enterprise: distributor) }

          it "will include a tax included amount on the voucher adjustment" do
            visit checkout_step_path(:details)

            choose "Delivery"

            click_button "Next - Payment method"

            # add Voucher
            fill_in "Enter voucher code", with: voucher.code
            click_button("Apply")

            # Choose payment ??
            click_on "Next - Order summary"
            click_on "Complete order"

            # UI checks
            expect(page).to have_content("Confirmed")
            expect(page).to have_selector('#order_total', text: with_currency(0.00))
            expect(page).to have_selector('#tax-row', text: with_currency(1.15))

            # Voucher
            within "#line-items" do
              expect(page).to have_content(voucher.code)
              expect(page).to have_content(with_currency(-10.00))
            end

            # DB check
            order_within_zone.reload
            voucher_adjustment = order_within_zone.voucher_adjustments.first

            expect(voucher_adjustment.amount.to_f).to eq(-10)
            expect(voucher_adjustment.included_tax.to_f).to eq(-1.15)
          end
        end
      end
    end

    describe "for a customer with shipping address outside the tax zone" do
      context "on legacy checkout" do
        before do
          set_order order_outside_zone
          login_as(user_outside_zone)
        end

        it "will not be charged tax on the order" do
          pending("#7540")
          visit checkout_path

          find(:xpath, '//*[@id="shipping"]/ng-form/dd').click
          choose free_shipping.name.to_s

          within "#payment" do
            choose free_payment.name.to_s
          end

          click_on "Place order now"

          # UI checks
          expect(page).to have_selector('#order_total', text: with_currency(10.00))
          expect(page).not_to have_content("includes tax")

          # DB checks
          assert_db_no_tax_incl
        end
      end

      context "on split-checkout" do
        before do
          Flipper.enable(:split_checkout)

          set_order order_outside_zone
          login_as(user_outside_zone)
        end

        it "will not be charged tax on the order" do
          pending("#7540")
          visit checkout_step_path(:details)

          choose "Delivery"
          check "order_save_bill_address"
          check "ship_address_same_as_billing"

          click_button "Next - Payment method"
          click_on "Next - Order summary"
          click_on "Complete order"

          # UI checks
          expect(page).to have_content("Confirmed")
          expect(page).to have_selector('#order_total', text: with_currency(10.00))
          expect(page).not_to have_content("includes tax")

          # DB checks
          assert_db_no_tax_incl
        end
      end
    end
  end

  private

  def assert_db_tax_incl
    order_within_zone.reload
    expect(order_within_zone.included_tax_total).to eq(1.15)
    expect(order_within_zone.additional_tax_total).to eq(0.0)
  end

  def assert_db_no_tax_incl
    order_outside_zone.reload
    expect(order_outside_zone.included_tax_total).to eq(0.0)
    expect(order_outside_zone.additional_tax_total).to eq(0.0)
  end
end
