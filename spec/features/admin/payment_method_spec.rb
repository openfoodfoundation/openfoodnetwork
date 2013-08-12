require "spec_helper"

feature %q{
    As a Super Admin
    I want to be able to set a distributor on each payment method
} do
  include AuthenticationWorkflow
  include WebHelper

  background do
    @distributors = (1..3).map { create(:distributor_enterprise) }
  end

  #Create and Edit uses same partial form
  context "creating a payment method", js: true do 
    scenario "assigning a distributor to the payment method" do
      login_to_admin_section

      click_link 'Configuration'
      click_link 'Payment Methods'
      click_link 'New Payment Method'

      fill_in 'payment_method_name', :with => 'Cheque payment method'

      select @distributors[0].name, :from => 'payment_method_distributor_id'
      click_button 'Create'

      flash_message.should == 'Payment Method has been successfully created!'
      
      payment_method = Spree::PaymentMethod.find_by_name('Cheque payment method')
      payment_method.distributor.should == @distributors[0]
    end
  end
end
