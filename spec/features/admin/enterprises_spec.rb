require "spec_helper"

feature %q{
    As an administrator
    I want to manage enterprises
} do
  include AuthenticationWorkflow
  include WebHelper

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

    fill_in 'enterprise_contact', :with => 'Kirsten or Ren'
    fill_in 'enterprise_phone', :with => '0413 897 321'
    fill_in 'enterprise_email_address', :with => 'info@eaterprises.com.au'
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
    # Make the page long enough to avoid the save bar overlaying the form
    page.driver.resize(1280, 1000)

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
      first("a", text: 'Edit Profile').trigger 'click'
    end

    fill_in 'enterprise_name', :with => 'Eaterprises'
    fill_in 'enterprise_permalink', with: 'eaterprises-permalink'
    page.should have_selector '.available'
    choose 'Own'

    # Require login to view shopfront or for checkout
    within(".side_menu") { click_link "Shop Preferences" }
    expect(page).to have_checked_field "enterprise_require_login_false"
    expect(page).to have_checked_field "enterprise_allow_guest_orders_true"
    choose "Visible to registered customers only"
    expect(page).to have_no_checked_field "enterprise_require_login_false"
    # expect(page).to have_checked_field "enterprise_enable_standing_orders_false"

    within(".side_menu") { click_link "Users" }
    select2_search user.email, from: 'Owner'
    expect(page).to have_no_selector '.select2-drop-mask' # Ensure select2 has finished

    click_link "About"
    fill_in 'enterprise_description', :with => 'Connecting farmers and eaters'

    # TODO: Directly altering the text in the contenteditable div like this started breaking with the upgrade
    # of Poltergeist from 1.5 to 1.7. Probably requires an upgrade of AngularJS and/or TextAngular
    # long_description = find :css, "text-angular#enterprise_long_description div.ta-scroll-window div.ta-bind"
    # long_description.set 'This is an interesting long description'
    # long_description.native.send_keys(:Enter) # Sets the value

    page.first("input[name='enterprise\[long_description\]']", visible: false).set('This is an interesting long description')

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
    fill_in 'enterprise_email_address', :with => 'info@eaterprises.com.au'
    fill_in 'enterprise_website', :with => 'http://eaterprises.com.au'

    click_link "Social"
    fill_in 'enterprise_twitter', :with => '@eaterprises'

    click_link "Business Details"
    fill_in 'enterprise_abn', :with => '09812309823'
    fill_in 'enterprise_acn', :with => ''
    choose 'Yes' # enterprise_charges_sales_tax

    click_link "Address"
    fill_in 'enterprise_address_attributes_address1', :with => '35 Ballantyne St'
    fill_in 'enterprise_address_attributes_city', :with => 'Thornbury'
    fill_in 'enterprise_address_attributes_zipcode', :with => '3072'
    select2_search 'Australia', :from => 'Country'
    select2_search 'Victoria', :from => 'State'

    click_link "Shop Preferences"
    # TODO: Same as above
    # shopfront_message = find :css, "text-angular#enterprise_preferred_shopfront_message div.ta-scroll-window div.ta-bind"
    # shopfront_message.set 'This is my shopfront message.'
    page.first("input[name='enterprise\[preferred_shopfront_message\]']", visible: false).set('This is my shopfront message.')
    page.should have_checked_field "enterprise_preferred_shopfront_order_cycle_order_orders_close_at"
    choose "enterprise_preferred_shopfront_order_cycle_order_orders_open_at"

    click_button 'Update'

    flash_message.should == 'Enterprise "Eaterprises" has been successfully updated!'
    page.should have_field 'enterprise_name', :with => 'Eaterprises'
    @enterprise.reload
    expect(@enterprise.owner).to eq user
    expect(page).to have_checked_field "enterprise_visible_true"

    click_link "Business Details"
    page.should have_checked_field "enterprise_charges_sales_tax_true"

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
    page.should have_checked_field "enterprise_preferred_shopfront_order_cycle_order_orders_open_at"
    expect(page).to have_checked_field "enterprise_require_login_true"
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

      # Then I should remain on the producer properties page
      expect(current_path).to eq main_app.admin_enterprise_producer_properties_path(s)

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

      # Then I should remain on the producer properties page
      expect(current_path).to eq main_app.admin_enterprise_producer_properties_path(s)

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
      click_button 'Update'

      # Then the property should have been removed
      expect(current_path).to eq main_app.admin_enterprise_producer_properties_path(s)
      page.should_not have_field 'enterprise_producer_properties_attributes_0_property_name', with: 'Certified Organic'
      s.producer_properties(true).should be_empty
    end
  end


  describe "inventory settings", js: true do
    let!(:enterprise) { create(:distributor_enterprise) }
    let!(:product) { create(:simple_product) }
    let!(:order_cycle) { create(:simple_order_cycle, distributors: [enterprise], variants: [product.variants.first]) }

    before do
      Delayed::Job.destroy_all
      quick_login_as_admin

      # This test relies on preference persistence, so we'll turn it on for this spec only.
      # It will be turned off again automatically by reset_spree_preferences in spec_helper.
      Spree::Preferences::Store.instance.persistence = true
    end

    it "refreshes the cache when I change what products appear on my shopfront" do
      # Given a product that's not in my inventory, but is in an active order cycle

      # When I change which products appear on the shopfront
      visit edit_admin_enterprise_path(enterprise)
      within(".side_menu") { click_link 'Inventory Settings' }
      choose 'enterprise_preferred_product_selection_from_inventory_only_1'

      # Then a job should have been enqueued to refresh the cache
      expect do
        click_button 'Update'
      end.to enqueue_job RefreshProductsCacheJob, distributor_id: enterprise.id, order_cycle_id: order_cycle.id
    end
  end

  context "as an Enterprise user", js: true do
    let(:supplier1) { create(:supplier_enterprise, name: 'First Supplier') }
    let(:supplier2) { create(:supplier_enterprise, name: 'Another Supplier') }
    let(:distributor1) { create(:distributor_enterprise, name: 'First Distributor') }
    let(:distributor2) { create(:distributor_enterprise, name: 'Another Distributor') }
    let(:distributor3) { create(:distributor_enterprise, name: 'Yet Another Distributor') }
    let(:enterprise_user) { create_enterprise_user }
    let!(:er) { create(:enterprise_relationship, parent: distributor3, child: distributor1, permissions_list: [:edit_profile]) }

    before(:each) do
      enterprise_user.enterprise_roles.build(enterprise: supplier1).save
      enterprise_user.enterprise_roles.build(enterprise: distributor1).save

      login_to_admin_as enterprise_user
    end

    context "when I have reached my enterprise ownership limit" do
      it "does not display the link to create a new enterprise" do
        supplier1.reload
        enterprise_user.owned_enterprises.push [supplier1]

        click_link "Enterprises"

        page.should have_content supplier1.name
        page.should have_content distributor1.name
        expect(find("#content-header")).to_not have_link "New Enterprise"
      end
    end

    context "creating an enterprise" do
      before do
        # When I create an enterprise
        click_link 'Enterprises'
        click_link 'New Enterprise'
        fill_in 'enterprise_name', with: 'zzz'
        fill_in 'enterprise_email_address', with: 'bob@example.com'
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
      within("tbody#e_#{distributor1.id}") { click_link 'Manage' }

      fill_in 'enterprise_name', :with => 'Eaterprises'

      # Because poltergist does not support form onchange event
      # We need trigger the change manually
      page.evaluate_script("angular.element(enterprise_form).scope().setFormDirty()")
      click_button 'Update'

      flash_message.should == 'Enterprise "Eaterprises" has been successfully updated!'
      distributor1.reload.name.should == 'Eaterprises'
    end

    describe "enterprises I have edit permission for, but do not manage" do
      it "allows me to edit them" do
        click_link 'Enterprises'
        within("tbody#e_#{distributor3.id}") { click_link 'Manage' }

        fill_in 'enterprise_name', :with => 'Eaterprises'

        # Because poltergist does not support form onchange event
        # We need trigger the change manually
        page.evaluate_script("angular.element(enterprise_form).scope().setFormDirty()")
        click_button 'Update'

        flash_message.should == 'Enterprise "Eaterprises" has been successfully updated!'
        distributor3.reload.name.should == 'Eaterprises'
      end

      it "does not show links to manage shipping methods, payment methods or enterprise fees on the edit page" do
        click_link 'Enterprises'
        within("tbody#e_#{distributor3.id}") { click_link 'Manage' }

        within(".side_menu") do
          page.should_not have_link 'Shipping Methods'
          page.should_not have_link 'Payment Methods'
          page.should_not have_link 'Enterprise Fees'
        end
      end
    end

    scenario "editing images for an enterprise" do
      click_link 'Enterprises'
      within("tbody#e_#{distributor1.id}") { click_link 'Manage' }

      within(".side_menu") do
        click_link "Images"
      end

      page.should have_content "LOGO"
      page.should have_content "PROMO"
    end

    scenario "managing producer properties" do
      create(:property, name: "Certified Organic")
      click_link 'Enterprises'
      within("#e_#{supplier1.id}") { click_link 'Manage' }
      within(".side_menu") do
        click_link "Properties"
      end

      # -- Update only
      select2_select "Certified Organic", from: 'enterprise_producer_properties_attributes_0_property_name'

      fill_in 'enterprise_producer_properties_attributes_0_value', with: "NASAA 12345"

      # Because poltergist does not support form onchange event
      # We need trigger the change manually
      page.evaluate_script("angular.element(enterprise_form).scope().setFormDirty()")
      click_button 'Update'

      supplier1.producer_properties(true).count.should == 1

      # -- Destroy
      pp = supplier1.producer_properties.first
      within(".side_menu") do
        click_link "Properties"
      end

      within("#spree_producer_property_#{pp.id}") { page.find('a.remove_fields').click }

      click_button 'Update'

      expect(page).to have_content 'Enterprise "First Supplier" has been successfully updated!'
      supplier1.producer_properties(true).should be_empty
    end
  end
end
