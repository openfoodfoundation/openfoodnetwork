require 'spec_helper'

feature %q{
    As a consumer
    I want to see a choice of order cycles and distributors
    So that I can shop for a particular distributor and pickup date
} do
  include AuthenticationWorkflow
  include WebHelper

  scenario "viewing order cycle and distributor choices", js: true do
    create(:itemwise_shipping_method)

    # Given some hubs and order cycles
    coord = create(:distributor_enterprise)
    d1 = create(:distributor_enterprise)
    d2 = create(:distributor_enterprise)
    create(:product, distributors: [d1, d2])

    oc1 = create(:simple_order_cycle, orders_close_at: Time.zone.now + 1.week)
    oc2 = create(:simple_order_cycle, orders_close_at: Time.zone.now + 2.days)
    create(:exchange, order_cycle: oc1, sender: oc1.coordinator, receiver: d1)
    create(:exchange, order_cycle: oc2, sender: oc2.coordinator, receiver: d2)

    # When I go to the product listing page
    visit spree.products_path

    # Then I should see a choice of hubs
    page.should have_selector "#distribution-choice option[value='#{d1.id}']", text: d1.name
    page.should have_selector "#distribution-choice option[value='#{d2.id}']", text: d2.name

    # And I should see a choice of order cycles with closing times
    [{oc: oc1, closing: '7 days'}, {oc: oc2, closing: '2 days'}].each do |data|
      within "tr.order-cycle-#{data[:oc].id}" do
        page.should have_content data[:oc].name
        page.should have_content data[:closing]
      end
    end
  end

  scenario "making an order cycle or distributor choice filters the remaining choices to valid options" do
    # When I select a hub
    # Then my choice of order cycles should be limited to that hub
    # When I select an order cycle
    # Then my choice of hubs should be limited to that order cycle
    pending
  end

  scenario "selecting an order cycle and distributor" do
    # When I select a hub and an order cycle and click "Select"
    # Then my distribution info should be set
    # And I should see my distribution info
    pending
  end

end
