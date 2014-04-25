require 'spec_helper'

feature 'Home', js: true do
  let(:distributor) { create(:distributor_enterprise) }
  before do
    distributor
    visit "/" 
  end

  it "shows all hubs" do
    page.should have_content distributor.name
    find("hub a.row").click
    page.should have_content "Shop at #{distributor.name}" 
  end

  pending "should grey out hubs that are not in an order cycle" do
    create(:simple_order_cycle, distributors: [d1, d3])
    create(:simple_product, distributors: [d1, d2])

    visit root_path

    page.should have_selector 'a.shop-distributor.active',   text: 'Murandaka'
    page.should have_selector 'a.shop-distributor.inactive', text: 'Ballantyne'
    page.should have_selector 'a.shop-distributor.active',   text: "O'Hea Street"
    page.should have_selector 'a.shop-distributor.inactive', text: 'PepperTree Place'
  end

  pending "should link to the hub page" do
    click_on 'Murandaka'
    current_path.should == "/shop"
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
end
