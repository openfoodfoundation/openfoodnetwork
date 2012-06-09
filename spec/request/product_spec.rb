require "spec_helper"

feature %q{
    As a supplier
    I want set a supplier for a product
} do
  # include AuthenticationWorkflow
  # include WebHelper

  background do
    # @booking = Booking.make_booking
    # @product_manager = User.make(:product_manager)
  end

  context "Given I am editing a booking" do
    scenario "I should be able to add a new note", :js =>true do
      # user = Factory(:admin_user, :email => "c@example.com")
      # sign_in_as!(user)

      # visit spree.admin_path
      # click_link 'New Product'
      # page.should have_content 'Notes'
      # fill_in 'booking_note_comment', :with => 'A new note !!!'
      # click_button 'Add note'

      # #flash_message.should == 'Booking Note successfully created.'

      # within('.notes-list') do
      #   page.should have_content('A new note !!!')
      #   page.should have_content(@product_manager.name)
      # end
      # click_link 'Back to Dashboard'
      # page.should have_content 'Booking details'
    end
  end
end
