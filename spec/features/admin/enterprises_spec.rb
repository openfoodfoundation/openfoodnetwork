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
      expect(page).to have_select "enterprise_set_collection_attributes_1_sells"
      expect(page).to have_content "Edit Profile"
      expect(page).to have_content "Delete"
      expect(page).to_not have_content "Payment Methods"
      expect(page).to_not have_content "Shipping Methods"
      expect(page).to have_content "Enterprise Fees"
    end

    within("tr.enterprise-#{d.id}") do
      expect(page).to have_content d.name
      expect(page).to have_select "enterprise_set_collection_attributes_0_sells"
      expect(page).to have_content "Edit Profile"
      expect(page).to have_content "Delete"
      expect(page).to have_content "Payment Methods"
      expect(page).to have_content "Shipping Methods"
      expect(page).to have_content "Enterprise Fees"
    end
  end

  context "editing enterprises in bulk" do
    let!(:s){ create(:supplier_enterprise) }
    let!(:d){ create(:distributor_enterprise, sells: 'none') }
    let!(:d_manager) { create_enterprise_user(enterprise_limit: 1) }

    before do
      d_manager.enterprise_roles.build(enterprise: d).save
      expect(d.owner).to_not eq d_manager
    end

    context "without violating rules" do
      before do
        login_to_admin_section
        click_link 'Enterprises'
      end

      it "updates the enterprises" do
        within("tr.enterprise-#{d.id}") do
          expect(page).to have_checked_field "enterprise_set_collection_attributes_0_visible"
          uncheck "enterprise_set_collection_attributes_0_visible"
          select 'any', from: "enterprise_set_collection_attributes_0_sells"
          select d_manager.email, from: 'enterprise_set_collection_attributes_0_owner_id'
        end
        click_button "Update"
        flash_message.should == 'Enterprises updated successfully'
        distributor = Enterprise.find(d.id)
        expect(distributor.visible).to eq false
        expect(distributor.sells).to eq 'any'
        expect(distributor.owner).to eq d_manager
      end
    end

    context "with data that violates rules" do
      let!(:second_distributor) { create(:distributor_enterprise, sells: 'none') }

      before do
        d_manager.enterprise_roles.build(enterprise: second_distributor).save
        expect(d.owner).to_not eq d_manager

        login_to_admin_section
        click_link 'Enterprises'
      end

      it "does not update the enterprises and displays errors" do
        within("tr.enterprise-#{d.id}") do
          select d_manager.email, from: 'enterprise_set_collection_attributes_0_owner_id'
        end
        within("tr.enterprise-#{second_distributor.id}") do
          select d_manager.email, from: 'enterprise_set_collection_attributes_1_owner_id'
        end
        click_button "Update"
        flash_message.should == 'Update failed'
        expect(page).to have_content "#{d_manager.email} is not permitted to own any more enterprises (limit is 1)."
        second_distributor.reload
        expect(second_distributor.owner).to_not eq d_manager
      end
    end
  end

  scenario "viewing an enterprise" do
    e = create(:enterprise)

    login_to_admin_section
    click_link 'Enterprises'
    click_link e.name

    page.should have_content e.name
  end

  scenario "creating a new enterprise", js: true do
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
    choose "Any"
    uncheck 'enterprise_is_primary_producer'

    page.should_not have_checked_field "enterprise_payment_method_ids_#{payment_method.id}"
    page.should_not have_checked_field "enterprise_shipping_method_ids_#{shipping_method.id}"

    # Filling in details
    fill_in 'enterprise_name', :with => 'Eaterprises'
    # This call intermittently fails to complete, leaving the select2 box open obscuring the
    # fields below it (which breaks the remainder of our specs). Calling it twice seems to
    # solve the problem.
    select2_search admin.email, from: 'Owner'
    select2_search admin.email, from: 'Owner'
    choose 'Any'

    fill_in 'enterprise_contact', :with => 'Kirsten or Ren'
    fill_in 'enterprise_phone', :with => '0413 897 321'
    fill_in 'enterprise_email', :with => 'info@eaterprises.com.au'
    fill_in 'enterprise_website', :with => 'http://eaterprises.com.au'

    fill_in 'enterprise_address_attributes_address1', :with => '35 Ballantyne St'
    fill_in 'enterprise_address_attributes_city', :with => 'Thornbury'
    fill_in 'enterprise_address_attributes_zipcode', :with => '3072'
    select2_search 'Australia', :from => 'Country'
    select2_search 'Victoria', :from => 'State'

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
    choose 'Own'
    select2_search user.email, from: 'Owner'

    click_link "About"
    fill_in 'enterprise_description', :with => 'Connecting farmers and eaters'
    long_description = find :css, "text-angular#enterprise_long_description div.ta-scroll-window div.ta-bind"
    long_description.set 'This is an interesting long description'

    # Check Angularjs switching of sidebar elements
    click_link "Primary Details"
    uncheck 'enterprise_is_primary_producer'
    choose 'None'
    page.should_not have_selector "#enterprise_fees"
    page.should_not have_selector "#payment_methods"
    page.should_not have_selector "#shipping_methods"
    check 'enterprise_is_primary_producer'
    page.should have_selector "#enterprise_fees"
    page.should_not have_selector "#payment_methods"
    page.should_not have_selector "#shipping_methods"
    uncheck 'enterprise_is_primary_producer'
    choose 'Own'
    page.should have_selector "#enterprise_fees"
    page.should have_selector "#payment_methods"
    page.should have_selector "#shipping_methods"
    choose 'Any'
    page.should have_selector "#enterprise_fees"
    page.should have_selector "#payment_methods"
    page.should have_selector "#shipping_methods"

    select2_search eg1.name, from: 'Groups'

    click_link "Payment Methods"
    page.should_not have_checked_field "enterprise_payment_method_ids_#{payment_method.id}"
    check "enterprise_payment_method_ids_#{payment_method.id}"

    click_link "Shipping Methods"
    page.should_not have_checked_field "enterprise_shipping_method_ids_#{shipping_method.id}"
    check "enterprise_shipping_method_ids_#{shipping_method.id}"

    click_link "Contact"
    fill_in 'enterprise_contact', :with => 'Kirsten or Ren'
    fill_in 'enterprise_phone', :with => '0413 897 321'
    fill_in 'enterprise_email', :with => 'info@eaterprises.com.au'
    fill_in 'enterprise_website', :with => 'http://eaterprises.com.au'

    click_link "Social"
    fill_in 'enterprise_twitter', :with => '@eaterprises'

    click_link "Business Details"
    fill_in 'enterprise_abn', :with => '09812309823'
    fill_in 'enterprise_acn', :with => ''

    click_link "Address"
    fill_in 'enterprise_address_attributes_address1', :with => '35 Ballantyne St'
    fill_in 'enterprise_address_attributes_city', :with => 'Thornbury'
    fill_in 'enterprise_address_attributes_zipcode', :with => '3072'
    select2_search 'Australia', :from => 'Country'
    select2_search 'Victoria', :from => 'State'

    click_link "Shop Preferences"
    shopfront_message = find :css, "text-angular#enterprise_preferred_shopfront_message div.ta-scroll-window div.ta-bind"
    shopfront_message.set 'This is my shopfront message.'

    click_button 'Update'

    flash_message.should == 'Enterprise "Eaterprises" has been successfully updated!'
    page.should have_field 'enterprise_name', :with => 'Eaterprises'
    @enterprise.reload
    expect(@enterprise.owner).to eq user

    click_link "Payment Methods"
    page.should have_checked_field "enterprise_payment_method_ids_#{payment_method.id}"

    click_link "Shipping Methods"
    page.should have_checked_field "enterprise_shipping_method_ids_#{shipping_method.id}"

    click_link "Enterprise Fees"
    page.should have_selector "td", text: enterprise_fee.name

    click_link "About"
    page.should have_content 'This is an interesting long description'

    click_link "Shop Preferences"
    page.should have_content 'This is my shopfront message.'
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
    let(:distributor3) { create(:distributor_enterprise, name: 'Yet Another Distributor') }
    let(:enterprise_user) { create_enterprise_user }
    let(:er) { create(:enterprise_relationship, parent: distributor3, child: distributor1, permissions_list: [:edit_profile]) }

    before(:each) do
      enterprise_user.enterprise_roles.build(enterprise: supplier1).save
      enterprise_user.enterprise_roles.build(enterprise: distributor1).save
      er

      login_to_admin_as enterprise_user
    end

    context "listing enterprises" do
      scenario "displays enterprises I have permission to manage" do
        oc_user_coordinating = create(:simple_order_cycle, { coordinator: supplier1, name: 'Order Cycle 1' } )
        oc_for_other_user = create(:simple_order_cycle, { coordinator: supplier2, name: 'Order Cycle 2' } )

        click_link "Enterprises"

        within("tr.enterprise-#{distributor1.id}") do
          expect(page).to have_content distributor1.name
          expect(page).to have_unchecked_field "enterprise_set_collection_attributes_0_is_primary_producer"
          expect(page).to_not have_select "enterprise_set_collection_attributes_0_sells"
        end

        within("tr.enterprise-#{distributor3.id}") do
          expect(page).to have_content distributor3.name
          expect(page).to have_unchecked_field "enterprise_set_collection_attributes_1_is_primary_producer"
          expect(page).to_not have_select "enterprise_set_collection_attributes_1_sells"
        end

        within("tr.enterprise-#{supplier1.id}") do
          expect(page).to have_content supplier1.name
          expect(page).to have_checked_field "enterprise_set_collection_attributes_2_is_primary_producer"
          expect(page).to_not have_select "enterprise_set_collection_attributes_2_sells"
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
        fill_in 'enterprise_email', with: 'bob@example.com'
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
          expect(page).to have_content "#{enterprise_user.email} is not permitted to own any more enterprises (limit is 1)."
        end
      end
    end

    scenario "editing enterprises I manage" do
      click_link 'Enterprises'
      within("#listing_enterprises tr.enterprise-#{distributor1.id}") { click_link 'Edit Profile' }

      fill_in 'enterprise_name', :with => 'Eaterprises'
      click_button 'Update'

      flash_message.should == 'Enterprise "Eaterprises" has been successfully updated!'
      distributor1.reload.name.should == 'Eaterprises'
    end

    describe "enterprises I have edit permission for, but do not manage" do
      it "allows me to edit them" do
        click_link 'Enterprises'
        within("#listing_enterprises tr.enterprise-#{distributor3.id}") { click_link 'Edit Profile' }

        fill_in 'enterprise_name', :with => 'Eaterprises'
        click_button 'Update'

        flash_message.should == 'Enterprise "Eaterprises" has been successfully updated!'
        distributor3.reload.name.should == 'Eaterprises'
      end

      it "does not show links to manage shipping methods, payment methods or enterprise fees" do
        click_link 'Enterprises'
        within("#listing_enterprises tr.enterprise-#{distributor3.id}") do
          page.should_not have_link 'Shipping Methods'
          page.should_not have_link 'Payment Methods'
          page.should_not have_link 'Enterprise Fees'
        end
      end

      it "does not show links to manage shipping methods, payment methods or enterprise fees on the edit page", js: true do
        click_link 'Enterprises'
        within("#listing_enterprises tr.enterprise-#{distributor3.id}") { click_link 'Edit Profile' }

        within(".side_menu") do
          page.should_not have_link 'Shipping Methods'
          page.should_not have_link 'Payment Methods'
          page.should_not have_link 'Enterprise Fees'
        end
      end
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
