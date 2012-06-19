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
    3.times { Spree::Distributor.make! }
  end

  scenario "viewing list of distributors" do
    # When I go to the home page
    visit spree.root_path

    # Then I should see a list containing all distributors
    Spree::Distributor.all.each do |distributor|
      page.should have_selector 'a', :text => distributor.name
    end
  end

  scenario "browsing products by distributor"

end
