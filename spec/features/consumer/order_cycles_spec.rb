require 'spec_helper'

feature %q{
    As a consumer
    I want to see a choice of order cycles and distributors
    So that I can shop for a particular distributor and pickup date
} do
  include AuthenticationWorkflow
  include WebHelper

  background do
    # Given some hubs and order cycles
    create(:distributor_enterprise)
    @d1 = create(:distributor_enterprise)
    @d2 = create(:distributor_enterprise)
    create(:product, distributors: [@d1, @d2])

    @oc1 = create(:simple_order_cycle, orders_close_at: Time.zone.now + 1.week)
    @oc2 = create(:simple_order_cycle, orders_close_at: Time.zone.now + 2.days)
    create(:exchange, order_cycle: @oc1, sender: @oc1.coordinator, receiver: @d1)
    create(:exchange, order_cycle: @oc2, sender: @oc2.coordinator, receiver: @d2)
  end

  describe 'when order cycles is enabled' do

    background do
      OrderCyclesHelper.class_eval do
        def order_cycles_enabled?
          true
        end
      end
    end


    scenario "selecting order cycle when multiple options are available", js: true do
      d = create(:distributor_enterprise, name: 'Green Grass')
      create_enterprise_group_for d
      oc1 = create(:simple_order_cycle, name: 'oc 1', distributors: [d])
      oc2 = create(:simple_order_cycle, name: 'oc 2', distributors: [d])

      # We find by ID because the scope returns read-only models
      exchange = Exchange.find(oc1.exchanges.to_enterprises(d).outgoing.first.id) 
      exchange.update_attribute :pickup_time, "turtles" 
      
      visit spree.root_path
      click_link d.name
      visit enterprise_path d

      page.should have_select 'order_order_cycle_id'
      select_by_value oc1.id, from: 'order_order_cycle_id'
      page.should have_content 'Your order will be ready on turtles'
    end

    context "when there are no available order cycles" do
      let(:d1) { create(:distributor_enterprise, name: 'Green Grass') }
      let(:d2) { create(:distributor_enterprise, name: 'Blue Grass') }
      before do
        create_enterprise_group_for d1
        visit spree.root_path
      end

      it "indicates there are no current order cycles" do
        Timecop.freeze do
          oc1 = create(:simple_order_cycle, name: 'oc 1', distributors: [d1], orders_close_at: 5.minutes.ago)
          oc2 = create(:simple_order_cycle, name: 'oc 1', distributors: [d2], orders_close_at: 3.minutes.ago)
          click_link d1.name
          visit enterprise_path d1

          page.should have_content "Orders are currently closed for this hub"
          page.should have_content "The last cycle closed 5 minutes ago"
          page.should have_content "Please contact your hub directly to see if they accept late orders, or wait until the next cycle opens."
          page.should have_content d1.email
          page.should have_content d1.phone
        end
      end

      context "displaying future order cycles" do
        it "should show the time until the next order cycle opens" do
          create(:simple_order_cycle, name: 'oc 1', distributors: [d1], orders_open_at: 10.days.from_now, orders_close_at: 11.days.from_now)

          click_link d1.name
          visit enterprise_path d1

          page.should have_content "The next order cycle opens in 10 days" 
        end

        it "should show nothing when there is no next order cycle" do
          click_link d1.name
          visit enterprise_path d1
          page.should_not have_content "The next order cycle opens" 
          page.should_not have_content "No products found"
        end
      end
    end

    scenario "changing order cycle", js: true do
      s = create(:supplier_enterprise)
      d = create(:distributor_enterprise, name: 'Green Grass')
      create_enterprise_group_for d
      p = create(:simple_product, supplier: s)
      oc = create(:simple_order_cycle, suppliers: [s], distributors: [d], variants: [p.master])

      visit spree.root_path
      click_link d.name
      visit enterprise_path d

      click_link p.name
      click_button 'Add To Cart'

      click_link 'Continue shopping'
      click_link 'Change Collection Date'
      

      # Then we should be back at the landing page with a reset cart
      page.should have_content 'Green Grass'
      page.should have_content 'When do you want your order?'
      # When we get taken back to select order cycle, there is no selected order cycle
      # Therefore we should not see the no products info
      page.should_not have_content "No products found"

      cart = Spree::Order.last
      cart.distributor.should == d
      cart.order_cycle.should be_nil
      cart.line_items.should be_empty
    end

    scenario "viewing order cycle and distributor choices", :future => true do
      # When I go to the product listing page
      visit spree.products_path

      # Then I should see a choice of hubs
      page.should have_selector "#distribution-selection option[value='#{@d1.id}']", text: @d1.name
      page.should have_selector "#distribution-selection option[value='#{@d2.id}']", text: @d2.name

      # And I should see a choice of order cycles with closing times
      [{oc: @oc1, closing: '7 days'}, {oc: @oc2, closing: '2 days'}].each do |data|
        within "tr.order-cycle-#{data[:oc].id}" do
          page.should have_content data[:oc].name
          page.should have_content data[:closing]
        end
      end

      # And I should see an indication of my current choices
      page.should have_selector "#distribution-choice", text: 'You have not yet picked where you will get your order from.'
    end

    scenario "order cycle expires mid-order" do
      d = create(:distributor_enterprise,
                 name: 'Green Grass', email: 'd@example.com', phone: '1029 3847')
      create_enterprise_group_for d
      p = create(:simple_product)
      oc = create(:simple_order_cycle, name: 'oc', distributors: [d], variants: [p.master])

      # When I select an order cycle and add a product to my cart
      visit spree.root_path
      click_link 'Green Grass'
      visit enterprise_path d
      click_link p.name
      click_button 'Add To Cart'

      # And the order cycle expires and I load a page
      Timecop.travel(oc.orders_close_at + 1.day) do
        click_link 'Continue shopping'

        # Then I should see an expiry message
        page.should have_content "Sorry, orders for this order cycle closed 1 day ago! Please contact your hub directly to see if they can accept late orders."
        page.should have_content d.email
        page.should have_content d.phone

        # And my cart should have been cleared
        page.should have_content "Cart: (Empty)"
        page.should have_content 'Green Grass'
      end
    end


    context "without javascript", :future => true do
      scenario "selecting a distributor highlights valid order cycle choices" do
        # When I go to the product listing page
        visit spree.products_path

        # And I choose a distributor
        select @d1.name, from: 'order_distributor_id'
        click_button 'Choose Hub'

        # Then associated order cycles should be highlighted
        page.should have_content "Your hub has been selected."
        page.should have_selector '#distribution-choice', text: "Hub: #{@d1.name}"
        within "#distribution-selection" do
          page.should have_selector "tr.order-cycle-#{@oc1.id}.local"
          page.should have_selector "tr.order-cycle-#{@oc2.id}.remote"
        end

        # When I choose the other distributor
        select @d2.name, from: 'order_distributor_id'
        click_button 'Choose Hub'

        # Then associated order cycles should be highlighted
        page.should have_content "Your hub has been selected."
        page.should have_selector '#distribution-choice', text: "Hub: #{@d2.name}"
        within '#distribution-selection' do
          page.should have_selector "tr.order-cycle-#{@oc1.id}.remote"
          page.should have_selector "tr.order-cycle-#{@oc2.id}.local"
        end
      end

      scenario "selecting an order cycle highlights valid distributor choices", :future => true do
        # When I go to the product listing page
        visit spree.products_path

        # And I choose an order cycle
        choose @oc1.name
        click_button 'Choose Order Cycle'

        # Then the associated distributor should be highlighted
        page.should have_content "Your order cycle has been selected."
        page.should have_selector '#distribution-choice', text: "Order Cycle: #{@oc1.name}"
        within '#distribution-selection' do
          page.should have_selector "option.local[value='#{@d1.id}']"
          page.should have_selector "option.remote[value='#{@d2.id}']"
        end

        # When I choose the other order cycle
        choose @oc2.name
        click_button 'Choose Order Cycle'

        # Then the associated distributor should be highlighted
        page.should have_content "Your order cycle has been selected."
        page.should have_selector '#distribution-choice', text: "Order Cycle: #{@oc2.name}"
        within '#distribution-selection' do
          page.should have_selector "option.remote[value='#{@d1.id}']"
          page.should have_selector "option.local[value='#{@d2.id}']"
        end
      end

      scenario "selecing a remote order cycle clears the distributor" do
        # When I go to the products listing page
        visit spree.products_path

        # And I choose a distributor
        select @d1.name, from: 'order_distributor_id'
        click_button 'Choose Hub'

        # And I choose a remote order cycle
        choose @oc2.name
        click_button 'Choose Order Cycle'

        # Then my distributor should be cleared
        page.should_not have_selector "option[value='#{@d1.id}'][selected='selected']"
      end

      scenario "selecing a remote distributor clears the order cycle" do
        # When I go to the products listing page
        visit spree.products_path

        # And I choose an order cycle
        choose @oc1.name
        click_button 'Choose Order Cycle'

        # And I choose a remote distributor
        select @d2.name, from: 'order_distributor_id'
        click_button 'Choose Hub'

        # Then my order cycle should be cleared
        page.should_not have_selector "input[value='#{@oc1.id}'][checked='checked']"
      end

      scenario "selecting both an order cycle and distributor", :future => true do
        # When I go to the products listing page
        visit spree.products_path

        # And I choose an order cycle
        choose @oc1.name
        click_button 'Choose Order Cycle'

        # And I choose a distributor
        select @d1.name, from: 'order_distributor_id'
        click_button 'Choose Hub'

        # Then my order cycle and distributor should be set
        within '#distribution-choice' do
          page.should have_content "Hub: #{@d1.name}"
          page.should have_content "Order Cycle: #{@oc1.name}"
        end

        page.should have_selector "input[value='#{@oc1.id}'][checked='checked']"
        page.should have_selector "option[value='#{@d1.id}'][selected='selected']"
      end
    end
  end

  describe 'when order cycles is disabled' do

    background do
      OrderCyclesHelper.class_eval do
        def order_cycles_enabled?
          false
        end
      end
    end

    scenario "should not show order cycles in the product listing" do
      # When I go to the product listing page
      visit spree.products_path

      # Then I should not see any hubs
      page.should_not have_selector "#distribution-selection"

      # And I should not display extra distribution details
      page.should_not have_selector "#distribution-choice"
    end
  end
end
