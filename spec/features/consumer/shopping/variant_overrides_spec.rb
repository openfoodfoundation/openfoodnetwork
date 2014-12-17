require 'spec_helper'

feature "shopping with variant overrides defined", js: true do
  include AuthenticationWorkflow
  include WebHelper
  include ShopWorkflow
  include UIComponentHelper

  use_short_wait

  describe "viewing products" do
    let(:hub) { create(:distributor_enterprise) }
    let(:producer) { create(:supplier_enterprise) }
    let(:oc) { create(:simple_order_cycle, suppliers: [producer], coordinator: hub, distributors: [hub]) }
    let(:outgoing_exchange) { oc.exchanges.outgoing.first }
    let(:product) { create(:simple_product, supplier: producer) }
    let(:variant) { create(:variant, product: product, price: 11.11) }
    let!(:vo) { create(:variant_override, hub: hub, variant: variant, price: 22.22) }

    before do
      outgoing_exchange.variants << variant
      visit shop_path
      click_link hub.name
    end

    it "shows the overridden price" do
      page.should_not have_price "$11.11"
      page.should have_price "$22.22"
    end

    it "takes stock from the override"
    it "calculates fees correctly"
    it "shows the overridden price with fees in the quick cart"
    it "shows the correct prices in the shopping cart"
    it "shows the correct prices in the checkout"
    it "creates the order with the correct prices"
  end
end
