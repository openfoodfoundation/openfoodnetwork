require 'spec_helper'

feature "full-page cart", js: true do
  include AuthenticationWorkflow
  include WebHelper
  include ShopWorkflow
  include UIComponentHelper

  describe "viewing the cart" do
    let!(:zone) { create(:zone_with_member) }
    let(:distributor) { create(:distributor_enterprise, with_payment_and_shipping: true, charges_sales_tax: true) }
    let(:supplier) { create(:supplier_enterprise) }
    let!(:order_cycle) { create(:simple_order_cycle, suppliers: [supplier], distributors: [distributor], coordinator: create(:distributor_enterprise), variants: [product.variants.first]) }
    let(:enterprise_fee) { create(:enterprise_fee, amount: 11.00, tax_category: product.tax_category) }
    let(:product) { create(:taxed_product, supplier: supplier, zone: zone, price: 110.00, tax_rate_amount: 0.1) }
    let(:variant) { product.variants.first }
    let(:order) { create(:order, order_cycle: order_cycle, distributor: distributor) }

    before do
      add_enterprise_fee enterprise_fee
      set_order order
      add_product_to_cart
      visit spree.cart_path
    end

    describe "tax" do
      it "shows the total tax for the order, including product tax and tax on fees" do
        page.should have_selector '.tax-total', text: '11.00' # 10 + 1
      end
    end

    describe "updating quantities with insufficient stock available" do
      let(:li) { order.line_items(true).last }

      before do
        variant.update_attributes! on_hand: 2
      end

      it "prevents me from entering an invalid value" do
        visit spree.cart_path

        accept_alert 'Insufficient stock available, only 2 remaining' do
          fill_in "order_line_items_attributes_0_quantity", with: '4'
        end

        page.should have_field "order_line_items_attributes_0_quantity", with: '2'
      end

      it "shows the quantities saved, not those submitted" do
        fill_in "order_line_items_attributes_0_quantity", with: '4'

        click_button 'Update'

        page.should have_field "order[line_items_attributes][0][quantity]", with: '1'
        page.should have_content "Insufficient stock available, only 2 remaining"
      end
    end
  end
end
