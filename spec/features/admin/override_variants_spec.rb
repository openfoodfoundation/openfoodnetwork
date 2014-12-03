require 'spec_helper'

feature %q{
  As an Administrator
  With products I can add to order cycles
  I want to override the stock level and price of those products
  Without affecting other hubs that share the same products
}, js: true do
  include AuthenticationWorkflow
  include WebHelper

  before do
    login_to_admin_section
  end

  use_short_wait

  let!(:hub) { create(:distributor_enterprise) }
  let!(:producer) { create(:supplier_enterprise) }

  describe "selecting a hub" do
    it "displays a list of hub choices" do
      visit '/admin/products/override_variants'
      page.should have_select2 'hub_id', options: ['', hub.name]
    end

    it "displays the hub" do
      visit '/admin/products/override_variants'
      select2_select hub.name, from: 'hub_id'
      click_button 'Go'

      page.should have_selector 'h2', text: hub.name
    end
  end

  context "when a hub is selected" do
    let!(:product) { create(:simple_product, supplier: producer, price: 1.23, on_hand: 12) }

    before do
      visit '/admin/products/override_variants'
      select2_select hub.name, from: 'hub_id'
      click_button 'Go'
    end

    it "displays the list of products" do
      page.should have_table_row ['PRODUCER', 'PRODUCT', 'PRICE', 'ON HAND']
      page.should have_table_row [producer.name, product.name, '1.23', '12']
    end

    it "products values are affected by overrides"
  end
end
