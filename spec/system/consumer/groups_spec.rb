# frozen_string_literal: true

require 'system_helper'

describe 'Groups' do
  include AuthenticationHelper
  include UIComponentHelper

  let(:enterprise) { create(:distributor_enterprise) }
  let!(:group) { create(:enterprise_group, enterprises: [enterprise], on_front_page: true) }

  it "renders groups" do
    visit groups_path
    expect(page).to have_content group.name
  end

  it "searches by URL" do
    visit groups_path(anchor: "/?query=xyzzy")
    expect(page).to have_content "No groups found"
  end

  describe "producers" do
    describe "filtering by product property" do
      let!(:producer1) { create(:supplier_enterprise) }
      let!(:producer2) { create(:supplier_enterprise) }

      let!(:product1) { create(:simple_product, supplier: producer1) }
      let!(:product2) { create(:simple_product, supplier: producer2) }

      before do
        product1.set_property 'Organic', 'NASAA 12345'
        product2.set_property 'Biodynamic', 'ABC123'

        producer1.set_producer_property 'Local', 'Victoria'
        producer2.set_producer_property 'Fair Trade', 'FT123'

        group.enterprises << producer1
        group.enterprises << producer2

        visit group_path(group, anchor: "/producers")
      end

      it "filters" do
        toggle_filters

        toggle_filter 'Organic'

        expect(page).to     have_content producer1.name
        expect(page).not_to have_content producer2.name

        toggle_filter 'Organic'
        toggle_filter 'Fair Trade'

        expect(page).not_to have_content producer1.name
        expect(page).to     have_content producer2.name
      end
    end
  end

  describe "hubs" do
    describe "filtering by product property" do
      let!(:group) {
        create(:enterprise_group, enterprises: [d1, d2, d3, d4], on_front_page: true)
      }
      let!(:order_cycle) {
        create(:simple_order_cycle, distributors: [d1, d2, d3],
                                    coordinator: create(:distributor_enterprise))
      }
      let!(:closed_order_cycle) {
        create(:closed_order_cycle, distributors: [d4],
                                    coordinator: create(:distributor_enterprise))
      }
      let(:producer) { create(:supplier_enterprise) }
      let(:d1) {
        create(:distributor_enterprise, with_payment_and_shipping: true, visible: "public")
      }
      let(:d2) {
        create(:distributor_enterprise, with_payment_and_shipping: true, visible: "public")
      }
      let(:d3) {
        create(:distributor_enterprise,
               with_payment_and_shipping: true,
               visible: "only_through_links")
      }
      let(:d4) {
        create(:distributor_enterprise, with_payment_and_shipping: true, visible: "public")
      }
      let(:p1) { create(:simple_product, supplier: producer) }
      let(:p2) { create(:simple_product, supplier: create(:supplier_enterprise)) }
      let(:p3) { create(:simple_product, supplier: create(:supplier_enterprise)) }
      let(:p4) { create(:simple_product, supplier: create(:supplier_enterprise)) }
      let(:ex_d1) { order_cycle.exchanges.outgoing.where(receiver_id: d1).first }
      let(:ex_d2) { order_cycle.exchanges.outgoing.where(receiver_id: d2).first }
      let(:ex_d3) { order_cycle.exchanges.outgoing.where(receiver_id: d3).first }
      let(:ex_d4) { closed_order_cycle.exchanges.outgoing.where(receiver_id: d4).first }

      before do
        producer.set_producer_property 'Organic', 'NASAA 12345'
        p2.set_property 'Local', 'XYZ 123'
        p3.set_property 'Not vibsible', 'Not vibsible'
        p4.set_property 'No active order cycle', 'No active order cycle'

        ex_d1.variants << p1.variants.first
        ex_d2.variants << p2.variants.first
        ex_d3.variants << p3.variants.first
        ex_d4.variants << p4.variants.first

        visit group_path(group, anchor: "/hubs")
      end

      it "adjusts visibilities of enterprises depending on their status" do
        expect(page).to     have_css('hub', text: d1.name)
        expect(page).to_not have_css('hub.inactive', text: d1.name)
        expect(page).to     have_css('hub', text: d2.name)
        expect(page).to_not have_css('hub.inactive', text: d2.name)
        expect(page).to_not have_text d3.name
        expect(page).to     have_css('hub.inactive', text: d4.name)
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
  end
end
