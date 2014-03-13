require 'spec_helper'

feature %q{
    As a consumer
    I want to see the landing page
    So I can choose a distributor
}, js: true do
  include AuthenticationWorkflow


  let(:d1) { create(:distributor_enterprise, name: 'Murandaka') }
  let(:d2) { create(:distributor_enterprise, name: 'Ballantyne') }
  let(:d3) { create(:distributor_enterprise, name: "O'Hea Street") }
  let(:d4) { create(:distributor_enterprise, name: "PepperTree Place") }

  let!(:eg1) { create(:enterprise_group, name: 'Group One',
                      on_front_page: true, enterprises: [d1, d2]) }
  let!(:eg2) { create(:enterprise_group, name: 'Group Two',
                      on_front_page: true, enterprises: [d3, d4]) }

  background do
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
      page.should have_link 'Login'
      page.should have_link 'Sign Up'
    end

    it "should not display links when signed in" do
      login_to_consumer_section
      visit root_path

      #page.should_not have_link 'Login'
      page.should_not have_selector('#sidebarLoginButton', visible: true)
      page.should_not have_selector('#sidebarSignUpButton', visible: true)
      #page.should_not have_link 'Sign Up'
    end
  end

  describe "hub list" do
    it "should display grouped hubs" do
      page.should have_content 'GROUP ONE'
      page.should have_link 'Murandaka'
      page.should have_link 'Ballantyne'

      page.should have_content 'GROUP TWO'
      page.should have_link "O'Hea Street"
      page.should have_link "PepperTree Place"
    end

    it "should grey out hubs that are not in an order cycle" do
      create(:simple_order_cycle, distributors: [d1, d3])
      create(:simple_product, distributors: [d1, d2])

      visit root_path

      page.should have_selector 'a.shop-distributor.active',   text: 'Murandaka'
      page.should have_selector 'a.shop-distributor.inactive', text: 'Ballantyne'
      page.should have_selector 'a.shop-distributor.active',   text: "O'Hea Street"
      page.should have_selector 'a.shop-distributor.inactive', text: 'PepperTree Place'
    end

    it "should link to the hub page" do
      click_on 'Murandaka'
      current_path.should == "/shop"
    end
  end

end
