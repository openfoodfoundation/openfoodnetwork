require "spec_helper"

feature %q{
    As a payment administrator
    I want to capture multiple payments quickly from the one page
} do
  include AuthenticationWorkflow
  include WebHelper

  background do
    #unfinished.. need to set up test data here
    @user = create(:user)    
    #ref: order_factory https://github.com/spree/spree/blob/b4353b88a4fc56fa95303a48409a623f68f7f659/core/lib/spree/testing_support/factories/order_factory.rb
    @orders = (1..3).map {create(:order_with_line_items, :user => @user, :bill_address => '', :ship_address => '')}
    
  end

  context "managing orders" do
    scenario "capture multiple payments from the orders index page" do
      #d.cook: could also test for an order that has had payment voided, then a new check payment created but not yet captured. But it's not critical and I know it works anyway.
      login_to_admin_section

      click_link 'Orders'
      
      @orders.each |order|
      
        #click the link for the order
        click_link "[data-action=capture]"
        #click_link "[data-action=capture][href|=R#{order.number}]" #not sure if possible to select value within an attribute value, |= doesn't work
        
        #we should be notified
        flash_message.should == "Payment Updated"
        
        #check the order was captured
        order.payment_status.should == :captured
        
        #we should still be on the right page
        
        
      end #orders.each
      

    end #scenario

  end #context
end
