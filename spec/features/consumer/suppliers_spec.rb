require 'spec_helper'

feature %q{
    As a consumer
    I want to see a list of products from a supplier
    So that I can connect with them (and maybe buy stuff too)
} do
  include AuthenticationWorkflow
  include WebHelper

  background do
    create(:distributor_enterprise, :name => "Edible garden")
  end

  scenario "entering the site via a supplier's page" do
    # Given a supplier with some distributed products
    s = create(:supplier_enterprise)
    d = create(:distributor_enterprise, with_payment_and_shipping: true)
    p = create(:simple_product, supplier: s)
    oc = create(:simple_order_cycle, suppliers: [s], distributors: [d], variants: [p.master])

    # When I visit a supplier page
    visit enterprise_path(s)

    # Then I should see a list of hubs that distribute the suppliers products
    page.should have_link d.name

    # When I click on a hub
    click_link d.name

    # Then that hub should be selected
    page.should have_content d.name
  end
end
