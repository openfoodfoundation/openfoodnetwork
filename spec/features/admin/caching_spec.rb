require 'spec_helper'
require 'open_food_network/products_renderer'

feature 'Caching' do
  include AuthenticationWorkflow
  include WebHelper

  before { quick_login_as_admin }

  describe "displaying integrity checker results" do
    let(:distributor) { create(:distributor_enterprise) }
    let(:order_cycle) { create(:open_order_cycle, distributors: [distributor]) }

    it "displays results when things are good" do
      # Given matching data
      Rails.cache.write "products-json-#{distributor.id}-#{order_cycle.id}", "[1, 2, 3]\n"
      OpenFoodNetwork::ProductsRenderer.stub(:new) { double(:pr, products_json: "[1, 2, 3]\n") }

      # When I visit the cache status page
      visit spree.admin_path
      click_link 'Configuration'
      click_link 'Caching'

      # Then I should see some status information
      page.should have_content "OK"
    end

    it "displays results when there are errors" do
      # Given matching data
      Rails.cache.write "products-json-#{distributor.id}-#{order_cycle.id}", "[1, 2, 3]\n"
      OpenFoodNetwork::ProductsRenderer.stub(:new) { double(:pr, products_json: "[1, 3]\n") }

      # When I visit the cache status page
      visit spree.admin_path
      click_link 'Configuration'
      click_link 'Caching'

      # Then I should see some status information
      page.should have_content "Error"
    end

  end
end
