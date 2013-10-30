require 'spec_helper'

feature %q{
    As a consumer
    I want to see the landing page
    So I can choose a distributor
}, js: true do
  include AuthenticationWorkflow

  background do
    d1 = create(:distributor_enterprise, name: 'Murandaka')
    d2 = create(:distributor_enterprise, name: 'Ballantyne')
    d3 = create(:distributor_enterprise, name: "O'Hea Street")

    eg1 = create(:enterprise_group, name: 'Group One', on_front_page: true, enterprises: [d1, d2])
    eg2 = create(:enterprise_group, name: 'Group Two', on_front_page: true, enterprises: [d3])

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

  describe "account links" do
    it "should display log in and sign up links when signed out" do
      page.should have_link 'Log in'
      page.should have_link 'Sign up'
    end

    it "should not display links when signed in" do
      login_to_consumer_section
      visit root_path

      page.should_not have_link 'Log in'
      page.should_not have_link 'Sign up'
    end
  end

  describe "hub list" do
    it "should display grouped hubs" do
      page.should have_content 'GROUP ONE'
      page.should have_link 'Murandaka'
      page.should have_link 'Ballantyne'

      page.should have_content 'GROUP TWO'
      page.should have_link "O'Hea Street"
    end

    it "should link to the hub page" do
      click_on 'Murandaka'
      page.should have_content 'CART'
    end
  end

end
