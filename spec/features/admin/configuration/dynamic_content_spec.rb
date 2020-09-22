require 'spec_helper'


# Defines the test link string
TEST_LINK = "ofn test link"

# Defines the test href string. This one should contain all non-encoding characters, for a URL
TEST_HREF = ":/?#@!$&'()*+,;=0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"


describe 'add dynamic content to homepage' do
	include AuthenticationHelper

	before(:each) do
		login_as_admin_and_visit spree.edit_admin_general_settings_path
	end 
	
		
	context 'edit the Content section', js: true do	
		before(:each) do
			click_link ("Content")
		end 


		# makes sure we are on the right page
		scenario 'while on the Content section' do
			
			#Q1: option 1 and/or
			expect(page).to have_current_path("/admin/contents/edit")

			#option 2?
			expect(page).to have_content("FOOTER AND EXTERNAL LINKS")

		end
		

		scenario 'insert content on Footer and Links and check homepage' do
			
			# adds content - text and a TEST_URL constant
			fill_in "footer_links_md", with: "[" + TEST_LINK + "]" + "(/" + TEST_HREF + ")"
       
        	# saves changes
        	click_button "Update"
        	
        	#sees "Update" banner
        	expect(page).to have_content("successfully updated!")

        	# logout and redirection to Homepage
            visit("/logout")

            # checks whether link and href are correctly converted and displayed in the homepage, after logout
            # Q2: would it be best to check this in separate "expect" lines? Or better this way, all in one line?
        	expect(page).to have_selector :link, TEST_LINK, href: "/" + TEST_HREF


			#Q3 - is defining strings in constants TEST_HREF TEST_LINK a good idea/practice? Or would it make sense to just use the strings directl on the examples above?        
			
        end

    end

end

