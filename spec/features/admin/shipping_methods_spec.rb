require 'spec_helper'

feature 'shipping methods' do
  include AuthenticationWorkflow
  include WebHelper

  before :each do
    login_to_admin_section
    @sm = create(:shipping_method)
  end

  scenario "creating a shipping method owned by a distributor" do
    # Given a distributor
    distributor = create(:distributor_enterprise, name: 'Aeronautical Adventures')

    # When I create a shipping method and set the distributor
    visit new_admin_shipping_method_path
    fill_in :name, with: 'Carrier Pidgeon'
    select 'Aeronautical Adventures', from: 'shipping_method_distributor_id'
    click_button 'Create'

    # Then the shipping method should have its distributor set
    flash_message.should == 'Your shipping method has been created'
    sm = Spree::ShippingMethod.last
    sm.name.should == 'Carrier Pidgeon'
    sm.distributor.should == distributor
  end

  it "shipping method requires distributor"
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
