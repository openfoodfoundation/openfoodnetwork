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

  scenario "viewing order cycle and distributor choices" do
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

  context "without javascript" do
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

    scenario "selecting an order cycle highlights valid distributor choices" do
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

    scenario "selecting both an order cycle and distributor" do
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

    scenario "selection form is not shown when there are products in the cart" do
      # Given a product
      d = create(:distributor_enterprise)
      p = create(:product, :distributors => [d])

      # When I go to the products listing page, I should see the selection form
      visit spree.products_path
      page.should have_selector "#distribution-selection"

      # When I add a product to the cart
      visit spree.product_path p
      select d.name, :from => 'distributor_id'
      click_button 'Add To Cart'

      # Then I should no longer see the selection form
      visit spree.products_path
      page.should_not have_selector "#distribution-selection"
    end
  end
end
