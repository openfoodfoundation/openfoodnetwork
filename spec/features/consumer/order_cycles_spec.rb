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
    page.should have_selector "#distribution-choice option[value='#{@d1.id}']", text: @d1.name
    page.should have_selector "#distribution-choice option[value='#{@d2.id}']", text: @d2.name

    # And I should see a choice of order cycles with closing times
    [{oc: @oc1, closing: '7 days'}, {oc: @oc2, closing: '2 days'}].each do |data|
      within "tr.order-cycle-#{data[:oc].id}" do
        page.should have_content data[:oc].name
        page.should have_content data[:closing]
      end
    end
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
      within '#distribution-choice' do
        page.should have_selector "tr.order-cycle-#{@oc1.id}.local"
        page.should have_selector "tr.order-cycle-#{@oc2.id}.remote"
      end

      # When I choose the other distributor
      select @d2.name, from: 'order_distributor_id'
      click_button 'Choose Hub'

      # Then associated order cycles should be highlighted
      within '#distribution-choice' do
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
      within '#distribution-choice' do
        page.should have_selector "option.local[value='#{@d1.id}']"
        page.should have_selector "option.remote[value='#{@d2.id}']"
      end

      # When I choose the other order cycle
      choose @oc2.name
      click_button 'Choose Order Cycle'

      # Then the associated distributor should be highlighted
      page.should have_content "Your order cycle has been selected."
      within '#distribution-choice' do
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
  end

  # scenario "making an order cycle or distributor choice filters the remaining choices to valid options", js: true do
  #   # When I go to the product listing page
  #   visit spree.products_path

  #   # And I select a hub
  #   select @d1.name, from: 'order_distributor_id'

  #   # Then my choice of order cycles should be limited to that hub
  #   page.should     have_selector "input#order_order_cycle_id_#{@oc1.id}"
  #   page.should_not have_selector "input#order_order_cycle_id_#{@oc1.id}"

  #   # When I select an order cycle
  #   select '', from: 'order_distributor_id'
  #   choose "order_distributor_id_#{@d2.id}"

  #   # Then my choice of hubs should be limited to that order cycle
  #   page.should_not have_selector "option[value='#{@d1.id}']", text: @d1.name
  #   page.should     have_selector "option[value='#{@d2.id}']", text: @d2.name
  # end

  scenario "selecting an order cycle and distributor" do
    # When I select a hub and an order cycle and click "Select"
    # Then my distribution info should be set
    # And I should see my distribution info
    pending
  end

end
