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
      expect(page).to have_content s.name
      expect(page).to have_select "enterprise_set_collection_attributes_1_type"
      expect(page).to have_content "Edit Profile"
      expect(page).to have_content "Delete"
      expect(page).to_not have_content "Payment Methods"
      expect(page).to_not have_content "Shipping Methods"
      expect(page).to have_content "Enterprise Fees"
    end

    within("tr.enterprise-#{d.id}") do
      expect(page).to have_content d.name
      expect(page).to have_select "enterprise_set_collection_attributes_0_type"
      expect(page).to have_content "Edit Profile"
      expect(page).to have_content "Delete"
      expect(page).to have_content "Payment Methods"
      expect(page).to have_content "Shipping Methods"
      expect(page).to have_content "Enterprise Fees"
    end
  end

  scenario "editing enterprises in bulk" do
    s = create(:supplier_enterprise)
    d = create(:distributor_enterprise, type: 'profile')
    d_manager = create_enterprise_user
    d_manager.enterprise_roles.build(enterprise: d).save
    expect(d.owner).to_not eq d_manager

    login_to_admin_section
    click_link 'Enterprises'

    within("tr.enterprise-#{d.id}") do
      expect(page).to have_checked_field "enterprise_set_collection_attributes_0_visible"
      uncheck "enterprise_set_collection_attributes_0_visible"
      select 'full', from: "enterprise_set_collection_attributes_0_type"
      select d_manager.email, from: 'enterprise_set_collection_attributes_0_owner_id'
    end
    click_button "Update"
    flash_message.should == 'Enterprises updated successfully'
    distributor = Enterprise.find(d.id)
    expect(distributor.visible).to eq false
    expect(distributor.type).to eq 'full'
    expect(distributor.owner).to eq d_manager
  end

  scenario "viewing an enterprise" do
    e = create(:enterprise)

    login_to_admin_section
    click_link 'Enterprises'
    click_link e.name

    page.should have_content e.name
  end

  scenario "creating a new enterprise", js:true do
    eg1 = create(:enterprise_group, name: 'eg1')
    eg2 = create(:enterprise_group, name: 'eg2')
    payment_method = create(:payment_method)
    shipping_method = create(:shipping_method)
    enterprise_fee = create(:enterprise_fee)

    # Navigating
    admin = quick_login_as_admin
    visit '/admin/enterprises'
    click_link 'New Enterprise'

    # Checking shipping and payment method sidebars work
    uncheck 'enterprise_is_primary_producer'
    check 'enterprise_is_distributor'
    page.should_not have_checked_field "enterprise_payment_method_ids_#{payment_method.id}"
    page.should_not have_checked_field "enterprise_shipping_method_ids_#{shipping_method.id}"

    # Filling in details
    fill_in 'enterprise_name', :with => 'Eaterprises'
    select2_search admin.email, from: 'Owner'
    choose 'Full'
    check "enterprise_payment_method_ids_#{payment_method.id}"
    check "enterprise_shipping_method_ids_#{shipping_method.id}"
    select2_search eg1.name, from: 'Groups'
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
    select2_search 'Australia', :from => 'Country'
    select2_search 'Victoria', :from => 'State'
    fill_in 'enterprise_description', :with => 'Connecting farmers and eaters'
    fill_in 'enterprise_long_description', :with => 'Zombie ipsum reversus ab viral inferno, nam rick grimes malum cerebro.'

    click_button 'Create'
    flash_message.should == 'Enterprise "Eaterprises" has been successfully created!'
  end

  scenario "editing an existing enterprise", js: true do
    @enterprise = create(:enterprise)
    e2 = create(:enterprise)
    eg1 = create(:enterprise_group, name: 'eg1')
    eg2 = create(:enterprise_group, name: 'eg2')
    payment_method = create(:payment_method, distributors: [e2])
    shipping_method = create(:shipping_method, distributors: [e2])
    enterprise_fee = create(:enterprise_fee, enterprise: @enterprise )
    user = create(:user)

    admin = quick_login_as_admin

    visit '/admin/enterprises'
    within "tr.enterprise-#{@enterprise.id}" do
      all("a", text: 'Edit Profile').first.click
    end

    fill_in 'enterprise_name', :with => 'Eaterprises'
    choose 'Single'
    select2_search user.email, from: 'Owner'
    fill_in 'enterprise_description', :with => 'Connecting farmers and eaters'
    fill_in 'enterprise_long_description', :with => 'Zombie ipsum reversus ab viral inferno, nam rick grimes malum cerebro.'

    # Check Angularjs switching of sidebar elements
    uncheck 'enterprise_is_primary_producer'
    uncheck 'enterprise_is_distributor'
    page.should have_selector "#payment_methods", visible: false
    page.should have_selector "#shipping_methods", visible: false
    page.should have_selector "#enterprise_fees", visible: false
    check 'enterprise_is_distributor'
    page.should have_selector "#payment_methods"
    page.should have_selector "#shipping_methods"
    page.should have_selector "#enterprise_fees"

    select2_search eg1.name, from: 'Groups'

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
    select2_search 'Australia', :from => 'Country'
    select2_search 'Victoria', :from => 'State'

    click_button 'Update'

    flash_message.should == 'Enterprise "Eaterprises" has been successfully updated!'
    page.should have_field 'enterprise_name', :with => 'Eaterprises'
    @enterprise.reload
    expect(@enterprise.owner).to eq user

    page.should have_checked_field "enterprise_payment_method_ids_#{payment_method.id}"
    page.should have_checked_field "enterprise_shipping_method_ids_#{shipping_method.id}"
    page.should have_selector "a.list-item", text: enterprise_fee.name
  end

  describe "producer properties" do
    it "creates producer properties" do
      # Given a producer enterprise
      s = create(:supplier_enterprise)

      # When I go to its properties page
      login_to_admin_section
      click_link 'Enterprises'
      within(".enterprise-#{s.id}") { click_link 'Properties' }

      # And I create a property
      fill_in 'enterprise_producer_properties_attributes_0_property_name', with: "Certified Organic"
      fill_in 'enterprise_producer_properties_attributes_0_value', with: "NASAA 12345"
      click_button 'Update'

      # Then I should be returned to the enterprises page
      page.should have_selector '#listing_enterprises a', text: s.name

      # And the producer should have the property
      s.producer_properties(true).count.should == 1
      s.producer_properties.first.property.presentation.should == "Certified Organic"
      s.producer_properties.first.value.should == "NASAA 12345"
    end

    it "updates producer properties" do
      # Given a producer enterprise with a property
      s = create(:supplier_enterprise)
      s.producer_properties.create! property_name: 'Certified Organic', value: 'NASAA 12345'

      # When I go to its properties page
      login_to_admin_section
      visit main_app.admin_enterprise_producer_properties_path(s)

      # And I update the property
      fill_in 'enterprise_producer_properties_attributes_0_property_name', with: "Biodynamic"
      fill_in 'enterprise_producer_properties_attributes_0_value', with: "Shininess"
      click_button 'Update'

      # Then I should be returned to the enterprises
      page.should have_selector '#listing_enterprises a', text: s.name

      # And the property should be updated
      s.producer_properties(true).count.should == 1
      s.producer_properties.first.property.presentation.should == "Biodynamic"
      s.producer_properties.first.value.should == "Shininess"
    end

    it "removes producer properties", js: true do
      # Given a producer enterprise with a property
      s = create(:supplier_enterprise)
      pp = s.producer_properties.create! property_name: 'Certified Organic', value: 'NASAA 12345'

      # When I go to its properties page
      login_to_admin_section
      visit main_app.admin_enterprise_producer_properties_path(s)

      # And I remove the property
      page.should have_field 'enterprise_producer_properties_attributes_0_property_name', with: 'Certified Organic'
      within("#spree_producer_property_#{pp.id}") { page.find('a.remove_fields').click }

      # Then the property should have been removed
      page.should_not have_selector '#progress'
      page.should_not have_field 'enterprise_producer_properties_attributes_0_property_name', with: 'Certified Organic'
      s.producer_properties(true).should be_empty
    end
  end


  context "as an Enterprise user" do
    let(:supplier1) { create(:supplier_enterprise, name: 'First Supplier') }
    let(:supplier2) { create(:supplier_enterprise, name: 'Another Supplier') }
    let(:distributor1) { create(:distributor_enterprise, name: 'First Distributor') }
    let(:distributor2) { create(:distributor_enterprise, name: 'Another Distributor') }
    let(:enterprise_user) { create_enterprise_user }

    before(:each) do
      enterprise_user.enterprise_roles.build(enterprise: supplier1).save
      enterprise_user.enterprise_roles.build(enterprise: distributor1).save

      login_to_admin_as enterprise_user
    end

    context "listing enterprises" do
      scenario "displays enterprises I have permission to manage" do
        oc_user_coordinating = create(:simple_order_cycle, { coordinator: supplier1, name: 'Order Cycle 1' } )
        oc_for_other_user = create(:simple_order_cycle, { coordinator: supplier2, name: 'Order Cycle 2' } )

        click_link "Enterprises"

        within("tr.enterprise-#{distributor1.id}") do
          expect(page).to have_content distributor1.name
          expect(page).to have_checked_field "enterprise_set_collection_attributes_0_is_distributor"
          expect(page).to have_unchecked_field "enterprise_set_collection_attributes_0_is_primary_producer"
          expect(page).to_not have_select "enterprise_set_collection_attributes_0_type"
        end

        within("tr.enterprise-#{supplier1.id}") do
          expect(page).to have_content supplier1.name
          expect(page).to have_unchecked_field "enterprise_set_collection_attributes_1_is_distributor"
          expect(page).to have_checked_field "enterprise_set_collection_attributes_1_is_primary_producer"
          expect(page).to_not have_select "enterprise_set_collection_attributes_1_type"
        end

        expect(page).to_not have_content "supplier2.name"
        expect(page).to_not have_content "distributor2.name"

        expect(find("#content-header")).to have_link "New Enterprise"
      end

      context "when I have reached my enterprise ownership limit" do
        it "does not display the link to create a new enterprise" do
          enterprise_user.owned_enterprises.push [supplier1]

          click_link "Enterprises"

          page.should have_content supplier1.name
          page.should have_content distributor1.name
          expect(find("#content-header")).to_not have_link "New Enterprise"
        end
      end
    end

    context "creating an enterprise" do
      before do
        # When I create an enterprise
        click_link 'Enterprises'
        click_link 'New Enterprise'
        fill_in 'enterprise_name', with: 'zzz'
        fill_in 'enterprise_address_attributes_address1', with: 'z'
        fill_in 'enterprise_address_attributes_city', with: 'z'
        fill_in 'enterprise_address_attributes_zipcode', with: 'z'
      end

      scenario "without violating rules" do
        click_button 'Create'

        # Then it should be created
        page.should have_content 'Enterprise "zzz" has been successfully created!'
        enterprise = Enterprise.last
        enterprise.name.should == 'zzz'

        # And I should be managing it
        Enterprise.managed_by(enterprise_user).should include enterprise
      end

      context "overstepping my owned enterprises limit" do
        before do
          create(:enterprise, owner: enterprise_user)
        end

        it "shows me an error message" do
          click_button 'Create'

          # Then it should show me an error
          expect(page).to_not have_content 'Enterprise "zzz" has been successfully created!'
          expect(page).to have_content "You are not permitted to own own any more enterprises (limit is 1)."
        end
      end
    end

    scenario "editing enterprises I have permission to" do
      click_link 'Enterprises'
      within('#listing_enterprises tbody tr:first') { click_link 'Edit Profile' }

      fill_in 'enterprise_name', :with => 'Eaterprises'
      click_button 'Update'

      flash_message.should == 'Enterprise "Eaterprises" has been successfully updated!'
      page.should have_field 'enterprise_name', :with => 'Eaterprises'
    end

    scenario "editing images for an enterprise" do
      click_link 'Enterprises'
      first(".edit").click
      page.should have_content "Logo"
      page.should have_content "Promo"
    end

    scenario "managing producer properties", js: true do
      click_link 'Enterprises'
      within(".enterprise-#{supplier1.id}") { click_link 'Properties' }

      # -- Create / update
      fill_in 'enterprise_producer_properties_attributes_0_property_name', with: "Certified Organic"
      fill_in 'enterprise_producer_properties_attributes_0_value', with: "NASAA 12345"
      click_button 'Update'
      page.should have_selector '#listing_enterprises a', text: supplier1.name
      supplier1.producer_properties(true).count.should == 1

      # -- Destroy
      pp = supplier1.producer_properties.first
      within(".enterprise-#{supplier1.id}") { click_link 'Properties' }

      within("#spree_producer_property_#{pp.id}") { page.find('a.remove_fields').click }
      page.should_not have_selector '#progress'
      supplier1.producer_properties(true).should be_empty
    end
  end
end
