require 'spec_helper'

feature "full-page cart", js: true do
  include AuthenticationWorkflow
  include WebHelper
  include ShopWorkflow
  include UIComponentHelper

  describe "viewing the cart" do
    describe "tax" do
      let!(:zone) { create(:zone_with_member) }
      let(:distributor) { create(:distributor_enterprise, with_payment_and_shipping: true, charges_sales_tax: true) }
      let(:supplier) { create(:supplier_enterprise) }
      let!(:order_cycle) { create(:simple_order_cycle, suppliers: [supplier], distributors: [distributor], coordinator: create(:distributor_enterprise), variants: [product.master]) }
      let(:enterprise_fee) { create(:enterprise_fee, amount: 11.00, tax_category: product.tax_category) }
      let(:product) { create(:taxed_product, supplier: supplier, zone: zone, price: 110.00, tax_rate_amount: 0.1) }
      let(:order) { create(:order, order_cycle: order_cycle, distributor: distributor) }

      before do
        add_enterprise_fee enterprise_fee
        set_order order
        add_product_to_cart
        visit spree.cart_path
      end

      it "shows the total tax for the order, including product tax and tax on fees" do
        save_screenshot '/home/rohan/ss.png', full: true
        page.should have_selector '.tax-total', text: '11.00' # 10 + 1
      end
    end
  end
end
