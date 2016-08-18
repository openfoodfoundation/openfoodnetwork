require 'spec_helper'

feature 'Groups', js: true do
  include AuthenticationWorkflow
  include UIComponentHelper

  let(:enterprise) { create(:distributor_enterprise) }
  let!(:group) { create(:enterprise_group, enterprises: [enterprise], on_front_page: true) }

  it "renders groups" do
    visit groups_path
    expect(page).to have_content group.name
  end

  it "searches by URL" do
    visit groups_path(anchor:  "/?query=xyzzy")
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
end
