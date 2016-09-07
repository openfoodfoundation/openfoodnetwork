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
    let!(:order_cycle) { create(:simple_order_cycle, suppliers: [supplier], distributors: [distributor], coordinator: create(:distributor_enterprise), variants: [product_tax.variants.first, product_fee.variants.first]) }
    let(:enterprise_fee) { create(:enterprise_fee, amount: 11.00, tax_category: product_tax.tax_category) }
    let(:product_tax) { create(:taxed_product, supplier: supplier, zone: zone, price: 110.00, tax_rate_amount: 0.1) }
    let(:product_fee) { create(:simple_product, supplier: supplier, price: 0.86, on_hand: 100) }
    let(:order) { create(:order, order_cycle: order_cycle, distributor: distributor) }

    before do
      set_order order
    end

    describe "fees" do
      let(:percentage_fee) { create(:enterprise_fee, calculator: Calculator::FlatPercentPerItem.new(preferred_flat_percent: 20)) }

      before do
        add_enterprise_fee percentage_fee
        add_product_to_cart order, product_fee, quantity: 8
        visit spree.cart_path
      end

      it "rounds fee calculations correctly" do
        # $0.86 + 20% = $1.032
        # Fractional cents should be immediately rounded down and not carried through
        expect(page).to have_selector '.cart-item-price',         text: '$1.03'
        expect(page).to have_selector '.cart-item-total',         text: '$8.24'
        expect(page).to have_selector '.order-total.item-total',  text: '$8.24'
        expect(page).to have_selector '.order-total.grand-total', text: '$8.24'
      end
    end

    describe "tax" do
      before do
        add_enterprise_fee enterprise_fee
        add_product_to_cart order, product_tax
        visit spree.cart_path
      end

      it "shows the total tax for the order, including product tax and tax on fees" do
        page.should have_selector '.tax-total', text: '11.00' # 10 + 1
      end
    end

    describe "updating quantities with insufficient stock available" do
      let(:li) { order.line_items(true).last }
      let(:variant) { product_tax.variants.first }

      before do
        add_product_to_cart order, product_tax
      end

      it "prevents me from entering an invalid value" do
        # Given we have 2 on hand, and we've loaded the page after that fact
        variant.update_attributes! on_hand: 2
        visit spree.cart_path

        accept_alert 'Insufficient stock available, only 2 remaining' do
          fill_in "order_line_items_attributes_0_quantity", with: '4'
        end

        page.should have_field "order_line_items_attributes_0_quantity", with: '2'
      end

      it "shows the quantities saved, not those submitted" do
        # Given we load the page with 3 on hand, then the number available drops to 2
        visit spree.cart_path
        variant.update_attributes! on_hand: 2

        fill_in "order_line_items_attributes_0_quantity", with: '4'

        click_button 'Update'

        page.should have_field "order[line_items_attributes][0][quantity]", with: '1'
        page.should have_content "Insufficient stock available, only 2 remaining"
      end
    end
  end
end
