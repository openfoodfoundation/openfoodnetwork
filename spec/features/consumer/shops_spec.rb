require 'spec_helper'

feature 'Shops', js: true do
  include AuthenticationWorkflow
  include UIComponentHelper

  let!(:distributor) { create(:distributor_enterprise, with_payment_and_shipping: true) }
  let!(:invisible_distributor) { create(:distributor_enterprise, visible: false) }
  let(:d1) { create(:distributor_enterprise) }
  let(:d2) { create(:distributor_enterprise) }
  let!(:order_cycle) { create(:simple_order_cycle, distributors: [distributor], coordinator: create(:distributor_enterprise)) }
  let!(:producer) { create(:supplier_enterprise) }
  let!(:er) { create(:enterprise_relationship, parent: distributor, child: producer) }

  before do
    producer.set_producer_property 'Organic', 'NASAA 12345'
  end

  it "searches by URL" do
    visit shops_path(anchor: "/?query=xyzzy")
    expect(page).to have_content "Sorry, no results found for xyzzy"
  end


  context "on the shops path" do
    before do
      visit shops_path
    end

    it "shows hubs" do
      page.should have_content distributor.name
      expand_active_table_node distributor.name
      page.should have_content "OUR PRODUCERS"
    end

    it "does not show invisible hubs" do
      page.should_not have_content invisible_distributor.name
    end

    it "should not show hubs that are not in an order cycle" do
      create(:simple_product, distributors: [d1, d2])
      visit shops_path
      page.should have_no_selector 'hub.inactive'
      page.should have_no_selector 'hub',   text: d2.name
    end

    it "should show closed shops after clicking the button" do
      create(:simple_product, distributors: [d1, d2])
      visit shops_path
      click_link_and_ensure("Show closed shops", -> { page.has_selector? 'hub.inactive' })
      page.should have_selector 'hub.inactive', text: d2.name
    end

    it "should link to the hub page" do
      follow_active_table_node distributor.name
      expect(page).to have_current_path enterprise_shop_path(distributor)
    end

    describe "property badges" do
      let!(:order_cycle) { create(:simple_order_cycle, distributors: [distributor], coordinator: create(:distributor_enterprise), variants: [product.variants.first]) }
      let(:product) { create(:simple_product, supplier: producer) }

      before do
        product.set_property 'Local', 'XYZ 123'
      end

      it "shows property badges" do
        # Given a shop with a product with a property
        # And the product's producer has a producer property

        # When I go to the shops path
        visit shops_path

        # And I open the shop
        expand_active_table_node distributor.name

        # Then I should see both properties
        expect(page).to have_content 'Local'   # Product property
        expect(page).to have_content 'Organic' # Producer property
      end
    end

    describe "hub producer modal" do
      let!(:product) { create(:simple_product, supplier: producer, taxons: [taxon]) }
      let!(:taxon) { create(:taxon, name: 'Fruit') }
      let!(:order_cycle) { create(:simple_order_cycle, distributors: [distributor], coordinator: create(:distributor_enterprise), variants: [product.variants.first]) }

      it "shows hub producer modals" do
        expand_active_table_node distributor.name
        expect(page).to have_content producer.name
        open_enterprise_modal producer
        modal_should_be_open_for producer

        within ".reveal-modal" do
          expect(page).to have_content 'Fruit'   # Taxon
          expect(page).to have_content 'Organic' # Producer property
        end
      end
    end
  end

  describe "viewing closed shops by URL" do
    before do
      d1
      d2
      visit shops_path(anchor: "/?show_closed=1")
    end

    it "shows closed shops" do
      #click_link_and_ensure("Show closed shops", -> { page.has_selector? 'hub.inactive' })
      page.should have_selector 'hub.inactive', text: d2.name
    end
  end


  private

  def click_link_and_ensure(link_text, check)
    # Buttons appear to be unresponsive for a while, so keep clicking them until content appears
    using_wait_time 0.5 do
      10.times do
        click_link link_text
        break if check.call
      end
    end
  end
end
