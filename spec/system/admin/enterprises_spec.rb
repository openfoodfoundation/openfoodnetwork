# frozen_string_literal: true

require "system_helper"

describe '
    As an administrator
    I want to manage enterprises
' do
  include WebHelper
  include AuthenticationHelper
  include ShopWorkflow
  include UIComponentHelper

  it "viewing an enterprise" do
    e = create(:enterprise)

    login_to_admin_section
    click_link 'Enterprises'
    click_link e.name

    expect(page).to have_content e.name
  end

  it "creating a new enterprise" do
    eg1 = create(:enterprise_group, name: 'eg1')
    eg2 = create(:enterprise_group, name: 'eg2')
    payment_method = create(:payment_method)
    shipping_method = create(:shipping_method)
    enterprise_fee = create(:enterprise_fee)

    # Navigating
    admin = login_as_admin
    visit '/admin/enterprises'
    click_link 'New Enterprise'

    # Checking shipping and payment method sidebars work
    choose "Any"
    uncheck 'enterprise_is_primary_producer'

    expect(page).not_to have_checked_field "enterprise_payment_method_ids_#{payment_method.id}"
    expect(page).not_to have_checked_field "enterprise_shipping_method_ids_#{shipping_method.id}"

    # Filling in details
    fill_in 'enterprise_name', with: 'Eaterprises'

    select2_select admin.email, from: 'enterprise_owner_id'

    fill_in 'enterprise_contact_name', with: 'Kirsten or Ren'
    fill_in 'enterprise_phone', with: '0413 897 321'
    fill_in 'enterprise_email_address', with: 'info@eaterprises.com.au'
    fill_in 'enterprise_website', with: 'http://eaterprises.com.au'

    fill_in 'enterprise_address_attributes_address1', with: '35 Ballantyne St'
    fill_in 'enterprise_address_attributes_city', with: 'Thornbury'
    fill_in 'enterprise_address_attributes_zipcode', with: '3072'
    fill_in 'enterprise_address_attributes_latitude', with: '-37.4713077'
    fill_in 'enterprise_address_attributes_longitude', with: '144.7851531'
    # default country (Australia in this test) should be selected by default
    page.find("#enterprise_address_attributes_country_id-ts-control").click
    page.find(".option", text: "Australia").click

    click_button 'Create'
    expect(flash_message).to eq('Enterprise "Eaterprises" has been successfully created!')
  end

  it "editing an existing enterprise" do
    @enterprise = create(:enterprise)
    e2 = create(:enterprise)
    eg1 = create(:enterprise_group, name: 'eg1')
    eg2 = create(:enterprise_group, name: 'eg2')
    payment_method = create(:payment_method, distributors: [e2])
    shipping_method = create(:shipping_method, distributors: [e2])
    enterprise_fee = create(:enterprise_fee, enterprise: @enterprise )
    user = create(:user)

    admin = login_as_admin

    visit '/admin/enterprises'
    within "tr.enterprise-#{@enterprise.id}" do
      first("a", text: 'Settings').click
    end

    fill_in 'enterprise_name', with: 'Eaterprises'
    fill_in 'enterprise_permalink', with: 'eaterprises-permalink'
    expect(page).to have_selector '.available'
    choose 'Own'

    # Require login to view shopfront or for checkout
    accept_alert do
      within(".side_menu") { click_link "Shop Preferences" }
    end
    expect(page).to have_checked_field "enterprise_require_login_false"
    expect(page).to have_checked_field "enterprise_allow_guest_orders_true"
    find(:xpath, '//*[@id="enterprise_require_login_true"]').trigger("click")
    expect(page).to have_no_checked_field "enterprise_require_login_false"
    # expect(page).to have_checked_field "enterprise_enable_subscriptions_false"

    accept_alert do
      within(".side_menu") { click_link "Users" }
    end
    select2_select user.email, from: 'enterprise_owner_id'
    expect(page).to have_no_selector '.select2-drop-mask' # Ensure select2 has finished

    accept_alert do
      click_link "About"
    end
    fill_in 'enterprise_description', with: 'Connecting farmers and eaters'

    description_input = page.find("text-angular#enterprise_long_description div[id^='taTextElement']")
    description_input.native.send_keys('This is an interesting long description')

    # Check StimulusJs switching of sidebar elements
    accept_alert do
      click_link "Primary Details"
    end
    # Unchecking hides the Properties tab
    uncheck 'enterprise_is_primary_producer'
    choose 'None'
    expect(page).not_to have_selector "#enterprise_fees"
    expect(page).not_to have_selector "#payment_methods"
    expect(page).not_to have_selector "#shipping_methods"
    expect(page).not_to have_selector "#properties"
    # Checking displays the Properties tab
    check 'enterprise_is_primary_producer'
    expect(page).to have_selector "#enterprise_fees"
    expect(page).not_to have_selector "#payment_methods"
    expect(page).not_to have_selector "#shipping_methods"
    expect(page).to have_selector "#properties"
    uncheck 'enterprise_is_primary_producer'
    choose 'Own'
    expect(page).to have_selector "#enterprise_fees"
    expect(page).to have_selector "#payment_methods"
    expect(page).to have_selector "#shipping_methods"
    choose 'Any'
    expect(page).to have_selector "#enterprise_fees"
    expect(page).to have_selector "#payment_methods"
    expect(page).to have_selector "#shipping_methods"

    page.find("#enterprise_group_ids-ts-control").set(eg1.name)
    page.find("#enterprise_group_ids-ts-dropdown .option.active").click

    within(".permalink") do
      link_path = "#{main_app.root_url}#{@enterprise.permalink}/shop"
      link = find_link(link)
      expect(link[:href]).to eq link_path
      expect(link[:target]).to eq '_blank'
    end

    accept_alert do
      click_link "Payment Methods"
    end
    expect(page).not_to have_checked_field "enterprise_payment_method_ids_#{payment_method.id}"
    check "enterprise_payment_method_ids_#{payment_method.id}"

    accept_alert do
      click_link "Shipping Methods"
    end
    expect(page).not_to have_checked_field "enterprise_shipping_method_ids_#{shipping_method.id}"
    check "enterprise_shipping_method_ids_#{shipping_method.id}"

    accept_alert do
      click_link "Contact"
    end
    fill_in 'enterprise_contact_name', with: 'Kirsten or Ren'
    fill_in 'enterprise_phone', with: '0413 897 321'
    fill_in 'enterprise_email_address', with: 'info@eaterprises.com.au'
    fill_in 'enterprise_website', with: 'http://eaterprises.com.au'

    accept_alert do
      click_link "Social"
    end
    fill_in 'enterprise_twitter', with: '@eaterprises'

    accept_alert do
      click_link "Business Details"
    end
    fill_in 'enterprise_abn', with: '09812309823'
    fill_in 'enterprise_acn', with: ''
    choose 'Yes' # enterprise_charges_sales_tax

    accept_alert do
      click_link "Address"
    end
    fill_in 'enterprise_address_attributes_address1', with: '35 Ballantyne St'
    fill_in 'enterprise_address_attributes_city', with: 'Thornbury'
    fill_in 'enterprise_address_attributes_zipcode', with: '3072'
    fill_in 'enterprise_address_attributes_latitude', with: '-37.4713077'
    fill_in 'enterprise_address_attributes_longitude', with: '144.7851531'
    # default country (Australia in this test) should be selected by default
    page.find("#enterprise_address_attributes_state_id-ts-control").click
    page.find(".option", text: "Victoria").click

    accept_alert do
      click_link "Shop Preferences"
    end
    shop_message_input = page.find("text-angular#enterprise_preferred_shopfront_message div[id^='taTextElement']")
    shop_message_input.native.send_keys('This is my shopfront message.')
    expect(page).to have_checked_field "enterprise_preferred_shopfront_order_cycle_order_orders_close_at"
    #using "find" as fields outside of the screen and are not visible
    find(:xpath, '//*[@id="enterprise_preferred_shopfront_order_cycle_order_orders_open_at"]').trigger("click")
    find(:xpath, '//*[@id="enterprise_enable_subscriptions_true"]').trigger("click")

    accept_alert do
      click_link "Inventory Settings"
    end
    expect(page).to have_checked_field "enterprise_preferred_product_selection_from_inventory_only_false"

    click_button 'Update'

    expect(flash_message).to eq('Enterprise "Eaterprises" has been successfully updated!')
    expect(page).to have_field 'enterprise_name', with: 'Eaterprises'
    @enterprise.reload
    expect(@enterprise.owner).to eq user
    expect(page).to have_checked_field "enterprise_visible_public"

    click_link "Business Details"
    expect(page).to have_checked_field "enterprise_charges_sales_tax_true"

    click_link "Payment Methods"
    expect(page).to have_checked_field "enterprise_payment_method_ids_#{payment_method.id}"

    click_link "Shipping Methods"
    expect(page).to have_checked_field "enterprise_shipping_method_ids_#{shipping_method.id}"

    click_link "Enterprise Fees"
    expect(page).to have_selector "td", text: enterprise_fee.name

    click_link "About"
    expect(page).to have_content 'This is an interesting long description'

    click_link "Shop Preferences"
    expect(page).to have_content 'This is my shopfront message.'
    expect(page).to have_checked_field "enterprise_preferred_shopfront_order_cycle_order_orders_open_at"
    expect(page).to have_checked_field "enterprise_require_login_true"
    expect(page).to have_checked_field "enterprise_enable_subscriptions_true"

    # Test that the right input alert text is displayed
    accept_alert('Please enter a URL to insert') do
      first('.ta-text').click
      first('button[name="insertLink"]').click
    end
  end

  describe "producer properties" do
    it "creates producer properties" do
      # Given a producer enterprise
      s = create(:supplier_enterprise)

      # When I go to its properties page
      login_as_admin_and_visit admin_enterprises_path
      within(".enterprise-#{s.id}") { click_link 'Properties' }

      # And I create a property
      fill_in 'enterprise_producer_properties_attributes_0_property_name', with: "Certified Organic"
      fill_in 'enterprise_producer_properties_attributes_0_value', with: "NASAA 12345"
      click_button 'Update'

      # Then I should remain on the producer properties page
      expect(current_path).to eq main_app.admin_enterprise_producer_properties_path(s)

      # And the producer should have the property
      expect(s.producer_properties.reload.count).to eq(1)
      expect(s.producer_properties.first.property.presentation).to eq("Certified Organic")
      expect(s.producer_properties.first.value).to eq("NASAA 12345")
    end

    it "updates producer properties" do
      # Given a producer enterprise with a property
      s = create(:supplier_enterprise)
      s.producer_properties.create! property_name: 'Certified Organic', value: 'NASAA 12345'

      # When I go to its properties page
      login_as_admin_and_visit main_app.admin_enterprise_producer_properties_path(s)

      # And I update the property
      fill_in 'enterprise_producer_properties_attributes_0_property_name', with: "Biodynamic"
      fill_in 'enterprise_producer_properties_attributes_0_value', with: "Shininess"
      click_button 'Update'

      # Then I should remain on the producer properties page
      expect(current_path).to eq main_app.admin_enterprise_producer_properties_path(s)

      # And the property should be updated
      expect(s.producer_properties.reload.count).to eq(1)
      expect(s.producer_properties.first.property.presentation).to eq("Biodynamic")
      expect(s.producer_properties.first.value).to eq("Shininess")
    end

    it "removes producer properties" do
      # Given a producer enterprise with a property
      s = create(:supplier_enterprise)
      pp = s.producer_properties.create! property_name: 'Certified Organic', value: 'NASAA 12345'

      # When I go to its properties page
      login_as_admin_and_visit main_app.admin_enterprise_producer_properties_path(s)

      # And I remove the property
      expect(page).to have_field 'enterprise_producer_properties_attributes_0_property_name',
                                 with: 'Certified Organic'
      within("#spree_producer_property_#{pp.id}") { page.find('a.remove_fields').click }
      click_button 'Update'

      # Then the property should have been removed
      expect(current_path).to eq main_app.admin_enterprise_producer_properties_path(s)
      expect(page).not_to have_field 'enterprise_producer_properties_attributes_0_property_name',
                                     with: 'Certified Organic'
      expect(s.producer_properties.reload).to be_empty
    end
  end

  context "as an Enterprise user" do
    let(:supplier1) { create(:supplier_enterprise, name: 'First Supplier') }
    let(:supplier2) { create(:supplier_enterprise, name: 'Another Supplier') }
    let(:distributor1) { create(:distributor_enterprise, name: 'First Distributor') }
    let(:distributor2) { create(:distributor_enterprise, name: 'Another Distributor') }
    let(:distributor3) { create(:distributor_enterprise, name: 'Yet Another Distributor') }
    let(:enterprise_user) { create(:user, enterprise_limit: 1) }
    let!(:er) {
      create(:enterprise_relationship, parent: distributor3, child: distributor1,
                                       permissions_list: [:edit_profile])
    }

    before(:each) do
      enterprise_user.enterprise_roles.build(enterprise: supplier1).save
      enterprise_user.enterprise_roles.build(enterprise: distributor1).save

      login_as enterprise_user
    end

    context "when I have reached my enterprise ownership limit" do
      it "shows a 'limit reached' modal message when trying to create a new enterprise" do
        supplier1.reload
        enterprise_user.owned_enterprises.push [supplier1]

        visit admin_enterprises_path

        expect(page).to have_content supplier1.name
        expect(page).to have_content distributor1.name

        within 'li#new_product_link' do
          expect(page).to have_link 'New Enterprise', href: '#'
          click_link 'New Enterprise'
        end

        expect(page).to have_content I18n.t('js.admin.enterprise_limit_reached',
                                            contact_email: ContentConfig.footer_email)
      end
    end

    context "creating an enterprise" do
      before do
        # When I create an enterprise
        visit admin_enterprises_path
        click_link 'New Enterprise'
        fill_in 'enterprise_name', with: 'zzz'
        fill_in 'enterprise_email_address', with: 'bob@example.com'
        fill_in 'enterprise_address_attributes_address1', with: 'z'
        fill_in 'enterprise_address_attributes_city', with: 'z'
        fill_in 'enterprise_address_attributes_zipcode', with: 'z'

        page.find("#enterprise_address_attributes_country_id-ts-control").click
        page.find(".option", text: "Australia").click

        page.find("#enterprise_address_attributes_state_id-ts-control").click
        page.find(".option", text: "Victoria").click
      end

      it "without violating rules" do
        click_button 'Create'

        # Then it should be created
        expect(page).to have_content 'Enterprise "zzz" has been successfully created!'
        enterprise = Enterprise.last
        expect(enterprise.name).to eq('zzz')

        # And I should be managing it
        expect(Enterprise.managed_by(enterprise_user)).to include enterprise
        expect(enterprise.contact).to eq enterprise.owner
      end

      context "overstepping my owned enterprises limit" do
        before do
          create(:enterprise, owner: enterprise_user)
        end

        it "shows me an error message" do
          click_button 'Create'

          # Then it should show me an error
          expect(page).to have_no_content 'Enterprise "zzz" has been successfully created!'
          expect(page).to have_content "#{enterprise_user.email} is not permitted to own any more enterprises (limit is 1)."
        end
      end
    end

    it "editing enterprises I manage" do
      visit admin_enterprises_path
      within("tbody#e_#{distributor1.id}") { click_link 'Settings' }

      fill_in 'enterprise_name', with: 'Eaterprises'

      # Because poltergist does not support form onchange event
      # We need trigger the change manually
      page.evaluate_script("angular.element(enterprise_form).scope().setFormDirty()")
      click_button 'Update'

      expect(flash_message).to eq('Enterprise "Eaterprises" has been successfully updated!')
      expect(distributor1.reload.name).to eq('Eaterprises')
    end

    describe "enterprises I have edit permission for, but do not manage" do
      it "allows me to edit them" do
        visit admin_enterprises_path
        within("tbody#e_#{distributor3.id}") { click_link 'Settings' }

        fill_in 'enterprise_name', with: 'Eaterprises'

        # Because poltergist does not support form onchange event
        # We need trigger the change manually
        page.evaluate_script("angular.element(enterprise_form).scope().setFormDirty()")
        click_button 'Update'

        expect(flash_message).to eq('Enterprise "Eaterprises" has been successfully updated!')
        expect(distributor3.reload.name).to eq('Eaterprises')
      end

      it "does not show links to manage shipping methods, payment methods or enterprise fees on the edit page" do
        visit admin_enterprises_path
        within("tbody#e_#{distributor3.id}") { click_link 'Settings' }

        within(".side_menu") do
          expect(page).not_to have_link 'Shipping Methods'
          expect(page).not_to have_link 'Payment Methods'
          expect(page).not_to have_link 'Enterprise Fees'
        end
      end
    end

    it "managing producer properties" do
      create(:property, name: "Certified Organic")
      visit admin_enterprises_path
      within("#e_#{supplier1.id}") { click_link 'Settings' }
      within(".side_menu") do
        click_link "Properties"
      end

      # -- Update only
      select2_select "Certified Organic",
                     from: 'enterprise_producer_properties_attributes_0_property_name'

      fill_in 'enterprise_producer_properties_attributes_0_value', with: "NASAA 12345"

      click_button 'Update'

      expect(supplier1.producer_properties.reload.count).to eq(1)

      # -- Destroy
      within(".side_menu") do
        click_link "Properties"
      end

      accept_alert do
        property = supplier1.producer_properties.first
        within("#spree_producer_property_#{property.id}") { page.find('a.remove_fields').click }
      end

      click_button 'Update'

      expect(page).to have_content 'Enterprise "First Supplier" has been successfully updated!'
      expect(supplier1.producer_properties.reload).to be_empty
    end

    describe "setting ordering preferences" do
      let(:taxon) { create(:taxon, name: "Tricky Taxon") }
      let(:property) { create(:property, presentation: "Fresh and Fine") }
      let(:user) { create(:user, enterprise_limit: 1) }
      let(:oc1) {
        create(:simple_order_cycle, distributors: [distributor1],
                                    coordinator: create(:distributor_enterprise), orders_close_at: 2.days.from_now)
      }
      let(:product) {
        create(:simple_product, supplier: supplier1, primary_taxon: taxon, properties: [property], name: "Beans")
      }
      let(:variant) { product.variants.first }
      let(:exchange1) { oc1.exchanges.to_enterprises(distributor1).outgoing.first }
      let(:order) { create(:order, distributor: distributor1) }

      before do
        exchange1.update_attribute :pickup_time, "monday"
        add_variant_to_order_cycle(exchange1, variant)
      end

      context "sorting by category" do
        before do
          visit edit_admin_enterprise_path(distributor1)

          within(".side_menu") do
            click_link "Shop Preferences"
          end

          choose "enterprise_preferred_shopfront_product_sorting_method_by_category"
          find("#taxon_select-ts-control").click
          find("#taxon_select-ts-dropdown").find('div', text: "Tricky Taxon").click
          click_button 'Update'
          expect(flash_message).to eq('Enterprise "First Distributor" has been successfully updated!')
        end

        it "sets the preference correctly" do
          expect(distributor1.preferred_shopfront_product_sorting_method).to eql("by_category")
          expect(distributor1.preferred_shopfront_taxon_order).to eql(taxon.id.to_s)
        end
      end

      context "sorting by producer" do
        before do
          visit edit_admin_enterprise_path(distributor1)

          within(".side_menu") do
            click_link "Shop Preferences"
          end

          choose "enterprise_preferred_shopfront_product_sorting_method_by_producer"
          find("#producer_select-ts-control").click
          find("#producer_select-ts-dropdown").find('div', text: "First Supplier").click
          click_button 'Update'
          expect(flash_message).to eq('Enterprise "First Distributor" has been successfully updated!')
        end

        it "sets the preference correctly" do
          expect(distributor1.preferred_shopfront_product_sorting_method).to eql("by_producer")
          expect(distributor1.preferred_shopfront_producer_order).to eql(supplier1.id.to_s)
        end
      end
    end
  end
end
