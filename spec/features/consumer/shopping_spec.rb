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
        oc1 = create(:simple_order_cycle, distributors: [distributor])
        exchange = Exchange.find(oc1.exchanges.to_enterprises(distributor).outgoing.first.id) 
        exchange.update_attribute :pickup_time, "turtles" 
        
        visit shop_index_path
        page.should have_selector "option[selected]", text: 'turtles'
        
        # Should see order cycle selected in dropdown
        # (Should also render products)
      end

      describe "with multiple order cycles" do
        let(:oc1) {create(:simple_order_cycle, distributors: [distributor])} 
        let(:oc2) {create(:simple_order_cycle, distributors: [distributor])} 
        before do
          exchange = Exchange.find(oc1.exchanges.to_enterprises(distributor).outgoing.first.id) 
          exchange.update_attribute :pickup_time, "frogs" 
          exchange = Exchange.find(oc2.exchanges.to_enterprises(distributor).outgoing.first.id) 
          exchange.update_attribute :pickup_time, "turtles" 
        end

        it "shows a select with all order cycles" do
          visit shop_index_path
          page.should have_selector "option", text: 'frogs'
          page.should have_selector "option", text: 'turtles'
          page.should_not have_selector "option[selected]"
        end

        it "allows the user to select an order cycle" do
          visit shop_index_path

          select "frogs", :from => "order_cycle_id"
          page.should have_content "Products"
        end
      end

      context "when no order cycles are available" do
        it "tells us orders are closed" do
          visit shop_index_path
          page.should have_content "Orders are currently closed for this hub"
        end
        it "shows the last order cycle" do
          oc1 = create(:simple_order_cycle, distributors: [distributor], orders_close_at: 10.days.ago)
          visit shop_index_path
          page.should have_content "The last cycle closed 10 days ago"
        end
        it "shows the next order cycle" do
          oc1 = create(:simple_order_cycle, distributors: [distributor], orders_open_at: 10.days.from_now)
          visit shop_index_path
          page.should have_content "The next cycle opens in 10 days"
        end
      end

    end
  end
end
