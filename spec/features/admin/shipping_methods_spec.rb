require 'spec_helper'

feature 'shipping methods' do
  include AuthenticationWorkflow
  include WebHelper

  before :each do
    login_to_admin_section
    @sm = create(:shipping_method)
  end

  scenario "creating a shipping method owned by some distributors" do
    # Given some distributors
    d1 = create(:distributor_enterprise, name: 'Aeronautical Adventures')
    d2 = create(:distributor_enterprise, name: 'Nautical Travels')

    # When I create a shipping method and set the distributors
    visit spree.new_admin_shipping_method_path
    fill_in 'shipping_method_name', with: 'Carrier Pidgeon'
    select 'Aeronautical Adventures', from: 'shipping_method_distributor_ids'
    select 'Nautical Travels', from: 'shipping_method_distributor_ids'
    click_button 'Create'

    # Then the shipping method should have its distributor set
    flash_message.should == 'Shipping method "Carrier Pidgeon" has been successfully created!'

    sm = Spree::ShippingMethod.last
    sm.name.should == 'Carrier Pidgeon'
    sm.distributors.should == [d1, d2]
  end

  it "at checkout, user can only see shipping methods for their current distributor (checkout spec)"


  scenario "deleting a shipping method" do
    visit_delete spree.admin_shipping_method_path(@sm)

    page.should have_content "Shipping method \"#{@sm.name}\" has been successfully removed!"
    Spree::ShippingMethod.where(:id => @sm.id).should be_empty
  end

  scenario "deleting a shipping method referenced by an order" do
    o = create(:order)
    o.shipping_method = @sm
    o.save!

    visit_delete spree.admin_shipping_method_path(@sm)

    page.should have_content "That shipping method cannot be deleted as it is referenced by an order: #{o.number}."
    Spree::ShippingMethod.find(@sm.id).should_not be_nil
  end
end
