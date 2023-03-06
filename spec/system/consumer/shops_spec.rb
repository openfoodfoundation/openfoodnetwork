# frozen_string_literal: true

require 'system_helper'

describe 'Shops' do
  include AuthenticationHelper
  include UIComponentHelper
  include WebHelper

  let!(:distributor) { create(:distributor_enterprise, with_payment_and_shipping: true) }
  let!(:invisible_distributor) { create(:distributor_enterprise, visible: false) }
  let!(:profile) { create(:distributor_enterprise, sells: 'none') }
  let!(:d1) { create(:distributor_enterprise, with_payment_and_shipping: true) }
  let!(:d2) { create(:distributor_enterprise, with_payment_and_shipping: true) }
  let!(:order_cycle) {
    create(:simple_order_cycle, distributors: [distributor],
                                coordinator: create(:distributor_enterprise))
  }
  let!(:producer) { create(:supplier_enterprise) }
  let!(:er) { create(:enterprise_relationship, parent: producer, child: distributor) }

  before do
    producer.set_producer_property 'Organic', 'NASAA 12345'
  end

  context "searching enterprises" do
    context "which exist" do
      it "by URL" do
        visit shops_path(anchor: "/?query=Enterprise")
        expect(page).to have_content "Did you mean? #{distributor.name}"
      end

      it "by typing in the search field" do
        visit shops_path
        find('input').set("Enterprise")
        expect(current_url).to have_content("/shops#/?query=Enterprise")
        expect(page).to have_content "Did you mean? #{distributor.name}"
      end
    end

    context "which do not exist" do
      it "by URL" do
        pending("#9649")
        visit shops_path(anchor: "/?query=xyzzy")
        sleep 1
        expect(page).not_to have_content distributor.name
        expect(page).to have_content "Sorry, no results found for xyzzy. Try another search?"
      end

      it "by typing in the search field" do
        pending("#5467")
        visit shops_path
        find('input').set("xyzzy")
        expect(current_url).to have_content("/shops#/?query=xyzzy")
        expect(page).not_to have_content distributor.name
        expect(page).to have_content "Sorry, no results found for xyzzy. Try another search?"
      end
    end
  end

  describe "listing shops" do
    before do
      visit shops_path
    end

    it "shows hubs" do
      expect(page).to have_content distributor.name
      expand_active_table_node distributor.name
      expect(page).to have_content "OUR PRODUCERS"
    end

    it "does not show invisible hubs" do
      expect(page).not_to have_content invisible_distributor.name
    end

    it "does not show hubs that are not in an order cycle" do
      expect(page).to have_no_selector 'hub.inactive'
      expect(page).to have_no_selector 'hub',   text: d2.name
    end

    it "does not show profiles" do
      expect(page).not_to have_content profile.name
    end

    it "shows closed shops after clicking the button" do
      click_link_and_ensure("Show closed shops", -> { page.has_selector? 'hub.inactive' })
      expect(page).to have_selector 'hub.inactive', text: d2.name
    end

    it "links to the hub page" do
      follow_active_table_node distributor.name
      expect(page).to have_current_path enterprise_shop_path(distributor)
    end
  end

  describe "showing available hubs" do
    let!(:hub) { create(:distributor_enterprise, with_payment_and_shipping: false) }
    let!(:order_cycle) { create(:simple_order_cycle, distributors: [hub], coordinator: hub) }
    let!(:producer) { create(:supplier_enterprise) }
    let!(:er) { create(:enterprise_relationship, parent: producer, child: hub) }

    it "does not show hubs that are not ready for checkout" do
      visit shops_path

      expect(Enterprise.ready_for_checkout).not_to include hub
      expect(page).not_to have_content hub.name
    end
  end

  describe "filtering by product property" do
    let!(:order_cycle) {
      create(:simple_order_cycle, distributors: [d1, d2],
                                  coordinator: create(:distributor_enterprise))
    }
    let!(:p1) { create(:simple_product, supplier: producer) }
    let!(:p2) { create(:simple_product, supplier: create(:supplier_enterprise)) }
    let(:ex_d1) { order_cycle.exchanges.outgoing.where(receiver_id: d1).first }
    let(:ex_d2) { order_cycle.exchanges.outgoing.where(receiver_id: d2).first }

    before do
      ex_d1.variants << p1.variants.first
      ex_d2.variants << p2.variants.first

      p2.set_property 'Local', 'XYZ 123'

      visit shops_path
    end

    it "filters" do
      toggle_filters

      toggle_filter 'Organic'

      expect(page).to     have_content d1.name
      expect(page).not_to have_content d2.name

      toggle_filter 'Organic'
      toggle_filter 'Local'

      expect(page).not_to have_content d1.name
      expect(page).to     have_content d2.name
    end
  end

  describe "taxon badges" do
    let!(:closed_oc) {
      create(:closed_order_cycle, distributors: [shop], variants: [p_closed.variants.first])
    }
    let!(:p_closed) { create(:simple_product, primary_taxon: taxon_closed, taxons: [taxon_closed]) }
    let(:shop) { create(:distributor_enterprise, with_payment_and_shipping: true) }
    let(:taxon_closed) { create(:taxon, name: 'Closed') }

    describe "open shops" do
      let!(:open_oc) {
        create(:open_order_cycle, distributors: [shop], variants: [p_open.variants.first])
      }
      let!(:p_open) { create(:simple_product, primary_taxon: taxon_open, taxons: [taxon_open]) }
      let(:taxon_open) { create(:taxon, name: 'Open') }

      it "shows taxons for open order cycles only" do
        visit shops_path
        expand_active_table_node shop.name
        expect(page).to     have_selector '.fat-taxons', text: 'Open'
        expect(page).not_to have_selector '.fat-taxons', text: 'Closed'
      end
    end

    describe "closed shops" do
      it "shows taxons for any order cycle" do
        visit shops_path
        click_link_and_ensure('Show closed shops', -> { page.has_selector? '.active_table_node' })
        expand_active_table_node shop.name
        expect(page).to have_selector '.fat-taxons', text: 'Closed'
      end
    end
  end

  describe "property badges" do
    let!(:order_cycle) {
      create(
        :simple_order_cycle,
        distributors: [distributor],
        coordinator: create(:distributor_enterprise),
        variants: [product.variants.first]
      )
    }
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
    let!(:order_cycle) {
      create(
        :simple_order_cycle,
        distributors: [distributor],
        coordinator: create(:distributor_enterprise),
        variants: [product.variants.first]
      )
    }

    it "shows hub producer modals" do
      visit shops_path
      expand_active_table_node distributor.name
      expect(page).to have_content producer.name
      open_enterprise_modal producer
      modal_should_be_open_for producer

      within ".reveal-modal" do
        expect(page).to have_content 'Fruit'   # Taxon
        expect(page).to have_content 'Organic' # Producer property
        expect(page).to have_content "Shop for #{producer.name} products at:".upcase
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
      expect(page).to have_selector 'hub.inactive', text: d2.name
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
