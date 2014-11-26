require 'spec_helper'

feature %q{
  As an Administrator
  With products I can add to order cycles
  I want to override the stock level and price of those products
  Without affecting other hubs that share the same products
}, js: true do
  include AuthenticationWorkflow
  include WebHelper

  use_short_wait

  let!(:hub) { create(:distributor_enterprise) }
  let!(:producer) { create(:supplier_enterprise) }
  let!(:er) { create(:enterprise_relationship, parent: producer, child: hub,
                     permissions_list: [:add_to_order_cycle]) }

  context "as an enterprise user" do
    let(:user) { create_enterprise_user enterprises: [hub, producer] }
    before { quick_login_as user }

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
      let!(:producer2) { create(:supplier_enterprise) }
      let!(:product2) { create(:simple_product, supplier: producer2, price: 1.23, on_hand: 12) }

      before do
        visit '/admin/products/override_variants'
        select2_select hub.name, from: 'hub_id'
        click_button 'Go'
      end

      it "displays the list of products" do
        page.should have_table_row ['PRODUCER', 'PRODUCT', 'PRICE', 'ON HAND']
        page.should have_table_row [producer.name, product.name, '1.23', '12']
      end

      it "filters the products to those the hub can add to an order cycle" do
        page.should_not have_table_row [producer2.name, product2.name, '1.23', '12']
      end

      it "products values are affected by overrides"
    end
  end
end
