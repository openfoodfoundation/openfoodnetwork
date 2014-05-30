require "spec_helper"

feature %q{
    As an administrator
    I want to manage enterprises
} do
  include AuthenticationWorkflow
  include WebHelper

  scenario "listing enterprises" do
    s = create(:supplier_enterprise)
    d = create(:distributor_enterprise)

    login_to_admin_section
    click_link 'Enterprises'

    within("tr.enterprise-#{s.id}") do
      page.should have_content s.name
      page.should have_content "Edit Profile"
      page.should have_content "Delete"
      page.should_not have_content "Payment Methods"
      page.should_not have_content "Shipping Methods"
      page.should have_content "Enterprise Fees"
    end

    within("tr.enterprise-#{d.id}") do
      page.should have_content d.name
      page.should have_content "Edit Profile"
      page.should have_content "Delete"
      page.should have_content "Payment Methods"
      page.should have_content "Shipping Methods"
      page.should have_content "Enterprise Fees"
    end
  end

  scenario "viewing an enterprise" do
    e = create(:enterprise)

    login_to_admin_section
    click_link 'Enterprises'
    click_link e.name

    page.should have_content e.name
  end

  scenario "creating a new enterprise" do
    eg1 = create(:enterprise_group, name: 'eg1')
    eg2 = create(:enterprise_group, name: 'eg2')
    payment_method = create(:payment_method)
    shipping_method = create(:shipping_method)
    enterprise_fee = create(:enterprise_fee)

    login_to_admin_section

    click_link 'Enterprises'
    click_link 'New Enterprise'

    fill_in 'enterprise_name', :with => 'Eaterprises'
    fill_in 'enterprise_description', :with => 'Connecting farmers and eaters'
    fill_in 'enterprise_long_description', :with => 'Zombie ipsum reversus ab viral inferno, nam rick grimes malum cerebro.'
    fill_in 'enterprise_distributor_info', :with => 'Zombie ipsum reversus ab viral inferno, nam rick grimes malum cerebro.'

    uncheck 'enterprise_is_primary_producer'
    check 'enterprise_is_distributor'

    select eg1.name, from: 'enterprise_group_ids'

    page.should_not have_checked_field "enterprise_payment_method_ids_#{payment_method.id}"
    page.should_not have_checked_field "enterprise_shipping_method_ids_#{shipping_method.id}"

    check "enterprise_payment_method_ids_#{payment_method.id}"
    check "enterprise_shipping_method_ids_#{shipping_method.id}"

    fill_in 'enterprise_contact', :with => 'Kirsten or Ren'
    fill_in 'enterprise_phone', :with => '0413 897 321'
    fill_in 'enterprise_email', :with => 'info@eaterprises.com.au'
    fill_in 'enterprise_website', :with => 'http://eaterprises.com.au'
    fill_in 'enterprise_twitter', :with => '@eaterprises'
    fill_in 'enterprise_facebook', :with => 'facebook.com/eaterprises'
    fill_in 'enterprise_instagram', :with => 'eaterprises'
    fill_in 'enterprise_abn', :with => '09812309823'
    fill_in 'enterprise_acn', :with => ''

    fill_in 'enterprise_address_attributes_address1', :with => '35 Ballantyne St'
    fill_in 'enterprise_address_attributes_city', :with => 'Thornbury'
    fill_in 'enterprise_address_attributes_zipcode', :with => '3072'
    select('Australia', :from => 'enterprise_address_attributes_country_id')
    select('Victoria', :from => 'enterprise_address_attributes_state_id')

    click_button 'Create'
    flash_message.should == 'Enterprise "Eaterprises" has been successfully created!'
  end

  scenario "editing an existing enterprise" do
    @enterprise = create(:enterprise)
    eg1 = create(:enterprise_group, name: 'eg1')
    eg2 = create(:enterprise_group, name: 'eg2')
    payment_method = create(:payment_method, distributors: [])
    shipping_method = create(:shipping_method, distributors: [])
    enterprise_fee = create(:enterprise_fee, enterprise: @enterprise )

    login_to_admin_section

    click_link 'Enterprises'
    click_link 'Edit Profile'

    fill_in 'enterprise_name', :with => 'Eaterprises'
    fill_in 'enterprise_description', :with => 'Connecting farmers and eaters'
    fill_in 'enterprise_long_description', :with => 'Zombie ipsum reversus ab viral inferno, nam rick grimes malum cerebro.'

    uncheck 'enterprise_is_primary_producer'
    check 'enterprise_is_distributor'

    select eg1.name, from: 'enterprise_group_ids'

    page.should_not have_checked_field "enterprise_payment_method_ids_#{payment_method.id}"
    page.should_not have_checked_field "enterprise_shipping_method_ids_#{shipping_method.id}"

    check "enterprise_payment_method_ids_#{payment_method.id}"
    check "enterprise_shipping_method_ids_#{shipping_method.id}"

    fill_in 'enterprise_contact', :with => 'Kirsten or Ren'
    fill_in 'enterprise_phone', :with => '0413 897 321'
    fill_in 'enterprise_email', :with => 'info@eaterprises.com.au'
    fill_in 'enterprise_website', :with => 'http://eaterprises.com.au'
    fill_in 'enterprise_twitter', :with => '@eaterprises'
    fill_in 'enterprise_abn', :with => '09812309823'
    fill_in 'enterprise_acn', :with => ''

    fill_in 'enterprise_address_attributes_address1', :with => '35 Ballantyne St'
    fill_in 'enterprise_address_attributes_city', :with => 'Thornbury'
    fill_in 'enterprise_address_attributes_zipcode', :with => '3072'
    select('Australia', :from => 'enterprise_address_attributes_country_id')
    select('Victoria', :from => 'enterprise_address_attributes_state_id')

    click_button 'Update'

    flash_message.should == 'Enterprise "Eaterprises" has been successfully updated!'
    page.should have_selector '#listing_enterprises a', text: 'Eaterprises'

    click_link 'Edit Profile'

    page.should have_checked_field "enterprise_payment_method_ids_#{payment_method.id}"
    page.should have_checked_field "enterprise_shipping_method_ids_#{shipping_method.id}"
    page.should have_selector "a.list-item", text: enterprise_fee.name
  end

  context 'as an Enterprise user' do
    let(:supplier1) { create(:supplier_enterprise, name: 'First Supplier') }
    let(:supplier2) { create(:supplier_enterprise, name: 'Another Supplier') }
    let(:distributor1) { create(:distributor_enterprise, name: 'First Distributor') }
    let(:distributor2) { create(:distributor_enterprise, name: 'Another Distributor') }

    before(:each) do
      @new_user = create_enterprise_user
      @new_user.enterprise_roles.build(enterprise: supplier1).save
      @new_user.enterprise_roles.build(enterprise: distributor1).save

      login_to_admin_as @new_user
    end

    scenario "can view enterprises I have permission to" do
      oc_user_coordinating = create(:simple_order_cycle, { coordinator: supplier1, name: 'Order Cycle 1' } )
      oc_for_other_user = create(:simple_order_cycle, { coordinator: supplier2, name: 'Order Cycle 2' } )

      click_link "Enterprises"

      page.should have_content supplier1.name
      page.should have_content distributor1.name
      page.should_not have_content supplier2.name
      page.should_not have_content distributor2.name
    end

    scenario "creating an enterprise" do
      # When I create an enterprise
      click_link 'Enterprises'
      click_link 'New Enterprise'
      fill_in 'enterprise_name', with: 'zzz'
      fill_in 'enterprise_address_attributes_address1', with: 'z'
      fill_in 'enterprise_address_attributes_city', with: 'z'
      fill_in 'enterprise_address_attributes_zipcode', with: 'z'
      click_button 'Create'

      # Then it should be created
      page.should have_content 'Enterprise "zzz" has been successfully created!'
      enterprise = Enterprise.last
      enterprise.name.should == 'zzz'

      # And I should be managing it
      Enterprise.managed_by(@new_user).should include enterprise
    end

    scenario "can edit enterprises I have permission to" do
      click_link 'Enterprises'
      within('#listing_enterprises tbody tr:first') { click_link 'Edit Profile' }

      fill_in 'enterprise_name', :with => 'Eaterprises'
      click_button 'Update'

      flash_message.should == 'Enterprise "Eaterprises" has been successfully updated!'
      page.should have_selector '#listing_enterprises a', text: 'Eaterprises'
    end

    scenario "Editing images for an enterprise" do
      click_link 'Enterprises'
      first(".edit").click
      page.should have_content "Logo"
      page.should have_content "Promo"
    end
  end
end
