require 'spec_helper'

feature %q{
    As a consumer
    I want to see a list of distributors
    So that I can shop by a particular distributor
} do
  include AuthenticationWorkflow
  include WebHelper

  background do
    # Given some distributors
    3.times { create(:distributor) }
  end

  scenario "viewing a list of distributors" do
    # When I go to the home page
    visit spree.root_path

    # Then I should see a list containing all distributors
    Spree::Distributor.all.each do |distributor|
      page.should have_selector 'a', :text => distributor.name
    end
  end


  context "when a distributor is selected" do
    it "displays the distributor's name" do
      # Given a distributor
      d = create(:distributor, :name => 'Melb Uni Co-op')

      # When I select the distributor
      visit spree.root_path
      click_link d.name

      # Then I should see the name of the distributor that I've selected
      page.should have_selector '.current-distributor', :text => 'You are shopping at Melb Uni Co-op'
    end

    it "splits the product listing by local/remote distributor"

    context "viewing a product" do
      it "provides a choice of distributor when adding to cart" # Test product at remote distributor
      it "displays the local distributor as the default choice when available for the current product"
    end
  end



  # scenario "browsing products by distributor" do
  #   # Given a product at each of two distributors
  #   d1 = create(:distributor)
  #   d2 = create(:distributor)
  #   p1 = create(:product, :distributors => [d1])
  #   p2 = create(:product, :distributors => [d2])

  #   # When I go to the home page, I should see both products
  #   visit spree.root_path
  #   page.should have_content p1.name
  #   page.should have_content p2.name

  #   # When I filter by one distributor, I should see only the product from that distributor
  #   click_link d1.name
  #   page.should have_content p1.name
  #   page.should_not have_content p2.name
  # end
end
