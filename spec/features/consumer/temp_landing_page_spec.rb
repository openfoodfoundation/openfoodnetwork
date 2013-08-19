require 'spec_helper'

feature %q{
    As a consumer
    I want to see the landing page
    So I choose a distributor
}, js: true do

  background do
    # for the link to be visible, it would also have to be in 'distributors.yml'
    FactoryGirl.create(:address, :address1 => "25 Myrtle Street", :zipcode => "3153", :city => "Bayswater")
    FactoryGirl.create(:distributor_enterprise, :name => "Green Grass", :address => Spree::Address.find_by_zipcode("3153"))
    visit root_path
  end

  describe "static content" do
    it "should have a logo" do
      page.should have_xpath("//img[@src=\"/assets/ofn_logo_black.png\"]")
    end

    it "should have explanatory text" do
      page.should have_content("WHERE WOULD YOU LIKE TO SHOP?")
    end
  end

  describe "hub list" do
    it "should display hub link" do
      page.should have_link("Green Grass")
    end

    it "should link to the hub page" do
      click_on "Green Grass"
      page.should have_content "CART"
    end
  end

end
