require "spec_helper"

feature %q{
    As a payment administrator
    I want to capture multiple payments quickly from the one page
} do
  include AuthenticationWorkflow
  include WebHelper

  background do
    @user = create(:user)    
    @order = create(:order_with_totals_and_distributor, :user => @user, :state => 'complete', :payment_state => 'balance_due')

    # ensure order has a payment to capture
    create :check_payment, order: @order, amount: @order.amount

    # ensure order shows up as completed
    #@order.completed_at = Time.now #to show up in list as completed
    #@order.save!
    @order.finalize! 
  end

  context "managing orders" do
    scenario "capture multiple payments from the orders index page" do
      # d.cook: could also test for an order that has had payment voided, then a new check payment created but not yet captured. But it's not critical and I know it works anyway.
      login_to_admin_section

      click_link 'Orders'
      #choose 'Only Show Complete Orders'
      #click_button 'Filter Results'
      
      # click the link for the order
      page.find("[data-action=capture][href*=#{@order.number}]").click
      
      # we should be notified
      flash_message.should == "Payment Updated"

      # check the order was captured
      @order.reload
      @order.payment_state.should == "paid"
      
      # we should still be on the right page
      page.should have_selector "h1", text: "Listing Orders" #t(:listing_orders)
      #current_path.should == admin_orders_path
        
    end # scenario
  end # context
end #f eature
