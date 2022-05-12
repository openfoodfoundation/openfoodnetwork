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

  let!(:user_within_zone) { create(:user, bill_address_id: address_within_zone.id,
    ship_address_id: address_within_zone.id) }

  let!(:user_outside_zone) { create(:user, bill_address_id: address_outside_zone.id,
    ship_address_id: address_outside_zone.id) }

  let!(:zone) { create(:zone_with_state_member, name: 'Victoria', default_tax: false) } 
  let!(:tax_category) { create(:tax_category, name: "Veggies", is_default: "f") }

  #sets up tax rate -> this is the setting Split-Checkout will consider. Updates below will not take effect (!)
  let!(:tax_rate) { create(:tax_rate, name: "Tax rate - included or not", amount: 0.13,
                            zone_id: zone.id, tax_category_id: tax_category.id, included_in_price: false)
  }

  let(:distributor) { create(:distributor_enterprise, charges_sales_tax: true) }
  let(:supplier) { create(:supplier_enterprise) }
  
  #sets up product
  let!(:product_with_tax) {
    create(:simple_product, supplier: supplier, price: 10, tax_category_id: tax_category.id)
  }
  let!(:variant_with_tax) { product_with_tax.variants.first }
  
  # sets up order cycle
  let!(:order_cycle) {
    create(:simple_order_cycle, suppliers: [supplier], distributors: [distributor],
                                coordinator: distributor, variants: [variant_with_tax])
  }
  
  let!(:free_shipping) {
    create(:shipping_method, distributors: [distributor], require_ship_address: false,
                              name: "Pick-up", description: "Payment without fee",
                              calculator: Calculator::FlatRate.new(preferred_amount: 0.00))
  }
  
  let!(:free_payment) {
    create(:payment_method, distributors: [distributor],
                          name: "Payment without Fee", description: "Payment without fee",
                          calculator: Calculator::FlatRate.new(preferred_amount: 0.00))
  }

  let!(:order_within_zone) {
    create(:order, order_cycle: order_cycle, distributor: distributor, user_id: user_within_zone.id,
      bill_address_id: address_within_zone.id, ship_address_id: address_within_zone.id, state: "cart",
                   line_items: [create(:line_item, variant: variant_with_tax)])
  }

  let!(:order_outside_zone) {
    create(:order, order_cycle: order_cycle, distributor: distributor, user_id: user_outside_zone.id,
      bill_address_id: address_outside_zone.id, ship_address_id: address_outside_zone.id, state: "cart",
                   line_items: [create(:line_item, variant: variant_with_tax)])
  }

    before do
      # assures tax is charged in dependence of shipping address
      Spree::Config.set(tax_using_ship_address: true)
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

      after {logout}
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
          choose "#{free_shipping.name}"

          within "#payment" do
            choose "#{free_payment.name}"
          end

          click_on "Place order now"

          # UI checks
          expect(page).to have_selector('#order_total', text: with_currency(11.30))
          expect(page).to have_selector('#tax-row', text: with_currency(1.30))

          # DB checks
          assert_db_tax
        end

        after {logout}
      end

      context "on split-checkout" do

        before do
          allow(Flipper).to receive(:enabled?).with(:split_checkout).and_return(true)
          allow(Flipper).to receive(:enabled?).with(:split_checkout, anything).and_return(true)

          set_order order_within_zone
          login_as(user_within_zone)
        end

        it "will be charged tax on the order" do
          visit checkout_step_path(:details)
          
          choose "Pick-up"

          click_button "Next - Payment method"
          click_on "Next - Order summary"
          click_on "Complete order"
          
          expect(page).to have_selector('#order_total', text: with_currency(11.30))
          expect(page).to have_selector('#tax-row', text: with_currency(1.30))

          #views confirmation page
          expect(page).to have_content("Confirmed")

          # DB checks
          assert_db_tax
        end
      end
    end

    describe "for a customer with shipping address outside the tax zone" do

      context "on legacy checkout" do

        before do
          set_order order_outside_zone
          login_as(user_outside_zone)
        end

        it "will be charged tax on the order" do

          visit checkout_path
          
          find(:xpath, '//*[@id="shipping"]/ng-form/dd').click
          choose "#{free_shipping.name}"

          within "#payment" do
            choose "#{free_payment.name}"
          end

          click_on "Place order now"

          # UI checks
          expect(page).to have_selector('#order_total', text: with_currency(10.00))
          expect(page).not_to have_content("includes tax")

          # DB checks
          assert_db_no_tax
        end

        after {logout}
      end

      context "on split-checkout" do

        before do
          allow(Flipper).to receive(:enabled?).with(:split_checkout).and_return(true)
          allow(Flipper).to receive(:enabled?).with(:split_checkout, anything).and_return(true)

          set_order order_outside_zone
          login_as(user_outside_zone)
        end

        it "will be charged tax on the order" do
          visit checkout_step_path(:details)
          
          choose "Pick-up"

          click_button "Next - Payment method"
          click_on "Next - Order summary"
          click_on "Complete order"
          
          expect(page).to have_selector('#order_total', text: with_currency(10.00))
          expect(page).not_to have_content("includes tax")

          #views confirmation page
          expect(page).to have_content("Confirmed")

          # DB checks
          assert_db_no_tax
        end
      end
    end
  end

end

private

def assert_db_tax
  # DB checks
  order_within_zone.reload # If page (above) was rendered containing the right values,
               #why do we need to reload the order? If we don't the spec fails.
  
  if tax_rate.included_in_price?
    expect(tax_rate.included_in_price).to eq(true)
    expect(order_within_zone.included_tax_total).to eq(0.115e1)
    expect(order_within_zone.additional_tax_total).to eq(0.0)
  else
    expect(tax_rate.included_in_price).to eq(false)
    expect(order_within_zone.included_tax_total).to eq(0.0)
    expect(order_within_zone.additional_tax_total).to eq(1.3)
  end
end

def assert_db_no_tax
  # DB checks
  order_outside_zone.reload # If page (above) was rendered containing the right values,
               #why do we need to reload the order? If we don't the spec fails.
  
  if tax_rate.included_in_price?
    expect(tax_rate.included_in_price).to eq(true)
    expect(order_outside_zone.included_tax_total).to eq(0.0)
    expect(order_outside_zone.additional_tax_total).to eq(0.0)
  else
    expect(tax_rate.included_in_price).to eq(false)
    expect(order_outside_zone.included_tax_total).to eq(0.0)
    expect(order_outside_zone.additional_tax_total).to eq(0.0)
  end
end
