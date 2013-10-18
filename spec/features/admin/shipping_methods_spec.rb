require 'spec_helper'

feature 'shipping methods' do
  include AuthenticationWorkflow
  include WebHelper

  before :each do
    @sm = create(:shipping_method)
  end

  context "as a site admin" do
    before(:each) do
      login_to_admin_section
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

  context "as an enterprise user" do
    let(:enterprise_user) { create_enterprise_user }
    let(:distributor1) { create(:distributor_enterprise, name: 'First Distributor') }
    let(:distributor2) { create(:distributor_enterprise, name: 'Second Distributor') }
    let(:sm1) { create(:shipping_method, name: 'One', distributors: [distributor1]) }
    let(:sm2) { create(:shipping_method, name: 'Two', distributors: [distributor2]) }

    before(:each) do
      enterprise_user.enterprise_roles.build(enterprise: distributor1).save
      enterprise_user.enterprise_roles.build(enterprise: distributor2).save
      login_to_admin_as enterprise_user
    end

    it "creates shipping methods" do
      click_link 'Enterprises'
      within(".enterprise-#{distributor1.id}") { click_link 'Shipping Methods' }
      click_link 'New Shipping Method'

      fill_in 'shipping_method_name', :with => 'Teleport'

      select distributor1.name, :from => 'shipping_method_distributor_ids'
      click_button 'Create'

      flash_message.should == 'Shipping method "Teleport" has been successfully created!'

      shipping_method = Spree::ShippingMethod.find_by_name('Teleport')
      shipping_method.distributors.should == [distributor1]
    end

    it "shows me only payment methods for the enterprise I select" do
      sm1
      sm2

      click_link 'Enterprises'
      within(".enterprise-#{distributor1.id}") { click_link 'Shipping Methods' }
      page.should     have_content sm1.name
      page.should_not have_content sm2.name

      click_link 'Enterprises'
      within(".enterprise-#{distributor2.id}") { click_link 'Shipping Methods' }
      page.should_not have_content sm1.name
      page.should     have_content sm2.name
    end
  end
end
