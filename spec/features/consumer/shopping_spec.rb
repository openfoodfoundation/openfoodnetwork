require 'spec_helper'

feature "As a consumer I want to shop with a distributor" do
  include AuthenticationWorkflow
  include WebHelper

  describe "Viewing a distributor" do
    let(:distributor) { create(:distributor_enterprise) }

    before do #temporarily using the old way to select distributor
      create_enterprise_group_for distributor
      visit "/"
      click_link distributor.name
    end
    it "shows a distributor" do
      visit shop_index_path
      page.should have_text distributor.name
    end

    describe "selecting an order cycle" do
      it "selects an order cycle if only one is open" do
        # create order cycle
        oc1 = create(:simple_order_cycle, name: 'oc 1', distributors: [distributor])
        exchange = Exchange.find(oc1.exchanges.to_enterprises(d).outgoing.first.id) 
        exchange.update_attribute :pickup_time, "turtles" 
        
        visit shop_index_path
        page.should have_selector "option[selected]", text: 'Packing'
        
        # Should see order cycle selected in dropdown
        # (Should also render products)
      end

      context "when no order cycles are available" do
        it "shows the last order cycle, if any"
        it "shows the next order cycle, if any"
      end

      it "renders the order cycle selector when multiple order cycles are available"
      it "allows the user to select an order cycle"
    end
  end
end
