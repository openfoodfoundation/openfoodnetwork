require 'spec_helper'

feature "Using embedded shopfront functionality", js: true do

  Capybara.server_port = 9999

  describe 'embedded groups' do
	let(:enterprise) { create(:distributor_enterprise) }
  	let!(:group) { create(:enterprise_group, enterprises: [enterprise], permalink: 'group1', on_front_page: true) }


  	before do
  	  Spree::Config[:enable_embedded_shopfronts] = true
      Spree::Config[:embedded_shopfronts_whitelist] = 'localhost'

      page.driver.browser.js_errors = false
	  Capybara.current_session.driver.visit('spec/support/views/group_iframe_test.html')

  	end

	it "displays in an iframe" do
	  expect(page).to have_selector 'iframe#group_test_iframe'

	  within_frame 'group_test_iframe' do
	  	within 'div#group-page' do
	  	  expect(page).to have_content 'About Us'
	  	end
	  end	  
	end
  
  end

end