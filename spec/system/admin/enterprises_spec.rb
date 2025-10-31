# frozen_string_literal: true

require "system_helper"

RSpec.describe '
    As an administrator
    I want to manage enterprises
' do
  include WebHelper
  include AuthenticationHelper
  include ShopWorkflow
  include UIComponentHelper
  include FileHelper

  it "viewing an enterprise" do
    e = create(:enterprise)

    login_to_admin_section
    click_link 'Enterprises'
    click_link e.name

    expect(page).to have_content e.name
  end

  it "creating a new enterprise" do
    admin = create(:admin_user)
    eg1 = create(:enterprise_group, name: 'eg1')
    eg2 = create(:enterprise_group, name: 'eg2')
    payment_method = create(:payment_method)
    shipping_method = create(:shipping_method)
    enterprise_fee = create(:enterprise_fee)

    # Navigating
    login_as admin
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

    # `Visible in search` radio button should be set to `Hide all references` by default
    expect(page).to have_checked_field "enterprise_visible_only_through_links"
  end

  it "deleting an existing enterprise successfully" do
    enterprise = create(:enterprise)

    user = create(:user)

    admin = login_as_admin

    visit '/admin/enterprises'

    expect do
      accept_alert do
        within "tr.enterprise-#{enterprise.id}" do
          first("a", text: 'Delete').click
        end
      end

      expect(page).to have_content("Successfully Removed")
    end.to change{ Enterprise.count }.by(-1)
  end

  it "deleting an existing enterprise unsuccessfully" do
    enterprise = create(:enterprise)
    create(:order, distributor: enterprise)

    user = create(:user)

    admin = login_as_admin

    visit '/admin/enterprises'

    expect do
      accept_alert do
        within "tr.enterprise-#{enterprise.id}" do
          first("a", text: 'Delete').click
        end
      end

      expect(page).to have_content("Cannot delete record because dependent distributed order")
      expect(page).to have_content(enterprise.name)
    end.to change{ Enterprise.count }.by(0)
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
      within(".side_menu") { find(:link, "Shop Preferences").trigger("click") }
    end
    expect(page).to have_checked_field "enterprise_require_login_false"
    expect(page).to have_checked_field "enterprise_allow_guest_orders_true"
    find(:xpath, '//*[@id="enterprise_require_login_true"]').trigger("click")
    expect(page).not_to have_checked_field "enterprise_require_login_false"
    # expect(page).to have_checked_field "enterprise_enable_subscriptions_false"

    choose('enterprise[show_customer_contacts_to_suppliers]', option: true)

    # See also "setting ordering preferences" tested separately.

    scroll_to(:bottom)
    accept_alert do
      scroll_to(:bottom)
      within(".side_menu") { click_link "Users" }
    end
    select2_select user.email, from: 'enterprise_owner_id'
    expect(page).not_to have_selector '.select2-drop-mask' # Ensure select2 has finished

    accept_alert do
      click_link "About"
    end
    fill_in 'enterprise_description', with: 'Connecting farmers and eaters'
    fill_in_trix_editor 'enterprise_long_description',
                        with: 'This is an interesting long description'

    # Check StimulusJs switching of sidebar elements
    accept_alert do
      click_link "Primary Details"
    end

    # Unchecking hides the Properties tab
    uncheck 'enterprise_is_primary_producer'
    choose 'None'
    expect(page).not_to have_selector "[data-test=link_for_enterprise_fees]"
    expect(page).not_to have_selector "[data-test=link_for_payment_methods]"
    expect(page).not_to have_selector "[data-test=link_for_shipping_methods]"
    expect(page).not_to have_selector "[data-test=link_for_properties]"
    # Checking displays the Properties tab
    check 'enterprise_is_primary_producer'
    expect(page).to have_selector "[data-test=link_for_enterprise_fees]"
    expect(page).not_to have_selector "[data-test=link_for_payment_methods]"
    expect(page).not_to have_selector "[data-test=link_for_shipping_methods]"
    expect(page).to have_selector "[data-test=link_for_properties]"
    uncheck 'enterprise_is_primary_producer'
    choose 'Own'
    expect(page).to have_selector "[data-test=link_for_enterprise_fees]"
    expect(page).to have_selector "[data-test=link_for_payment_methods]"
    expect(page).to have_selector "[data-test=link_for_shipping_methods]"
    choose 'Any'
    expect(page).to have_selector "[data-test=link_for_enterprise_fees]"
    expect(page).to have_selector "[data-test=link_for_payment_methods]"
    expect(page).to have_selector "[data-test=link_for_shipping_methods]"

    page.find("#enterprise_group_ids-ts-control").set(eg1.name)
    page.find("#enterprise_group_ids-ts-dropdown .option.active").click

    within(".permalink") do
      link_path = "#{main_app.root_url}#{@enterprise.permalink}/shop"
      link = find_link(link_path)
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
      within(".side_menu") { find(:link, "Shop Preferences").trigger("click") }
    end
    fill_in_trix_editor 'enterprise_preferred_shopfront_message',
                        with: 'This is my shopfront message.'
    expect(page)
      .to have_checked_field "enterprise_preferred_shopfront_order_cycle_order_orders_close_at"
    # using "find" as fields outside of the screen and are not visible
    find(:xpath, '//*[@id="enterprise_preferred_shopfront_order_cycle_order_orders_open_at"]')
      .trigger("click")
    find(:xpath, '//*[@id="enterprise_enable_subscriptions_true"]').trigger("click")

    # Save changes
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

    within(".side_menu") { find(:link, "Shop Preferences").trigger("click") }
    expect(page).to have_content 'This is my shopfront message.'
    expect(page).to have_checked_field(
      "enterprise_preferred_shopfront_order_cycle_order_orders_open_at"
    )
    expect(page).to have_checked_field "enterprise_require_login_true"
    expect(page).to have_checked_field "enterprise_enable_subscriptions_true"
    expect(page).to have_checked_field 'enterprise[show_customer_contacts_to_suppliers]', with: true

    # Back navigation loads the tab content
    page.execute_script('window.history.back()')
    expect(page).to have_selector '#enterprise_description'

    # Forward navigation brings back the previous tab
    page.execute_script('window.history.forward()')
    expect(page).to have_content 'This is my shopfront message.'

    # Test Trix editor translations are loaded
    find(".trix-button--icon-link").click
    expect(page).to have_selector(
      "input[aria-label=URL][placeholder='Please enter a URL to insert']"
    )
  end

  context "with inventory enabled", feature: :inventory do
    it "allows editing inventory settings" do
      enterprise = create(:enterprise)

      admin = login_as_admin

      visit '/admin/enterprises'
      within "tr.enterprise-#{enterprise.id}" do
        first("a", text: 'Settings').click
      end

      click_link "Inventory Settings"
      expect(page).to have_checked_field(
        "enterprise_preferred_product_selection_from_inventory_only_false"
      )

      page.find("#enterprise_preferred_product_selection_from_inventory_only_true").click
      click_button 'Update'

      click_link "Inventory Settings"
      expect(page).to have_checked_field(
        "enterprise_preferred_product_selection_from_inventory_only_true"
      )
    end
  end

  describe "producer properties" do
    it "creates producer properties" do
      # Given a producer enterprise
      s = create(:supplier_enterprise)

      # When I go to its properties page
      login_as_admin
      visit admin_enterprises_path
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
      login_as_admin
      visit main_app.admin_enterprise_producer_properties_path(s)

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
      login_as_admin
      visit main_app.admin_enterprise_producer_properties_path(s)

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
          expect(page).not_to have_content 'Enterprise "zzz" has been successfully created!'
          expect(page).to have_content "#{enterprise_user.email} is not permitted " \
                                       "to own any more enterprises (limit is 1)."
        end
      end
    end

    it "editing enterprises I manage" do
      visit admin_enterprises_path
      within("tbody#e_#{distributor1.id}") { click_link 'Settings' }

      fill_in 'enterprise_name', with: 'Eaterprises'
      click_button 'Update'

      expect(flash_message).to eq('Enterprise "Eaterprises" has been successfully updated!')
      expect(distributor1.reload.name).to eq('Eaterprises')
    end

    describe "enterprises I have edit permission for, but do not manage" do
      it "allows me to edit them" do
        visit admin_enterprises_path
        within("tbody#e_#{distributor3.id}") { click_link 'Settings' }

        fill_in 'enterprise_name', with: 'Eaterprises'
        click_button 'Update'

        expect(flash_message).to eq('Enterprise "Eaterprises" has been successfully updated!')
        expect(distributor3.reload.name).to eq('Eaterprises')
      end

      it "does not show links to manage shipping methods, payment methods or " \
         "enterprise fees on the edit page" do
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
                                    coordinator: create(:distributor_enterprise),
                                    orders_close_at: 2.days.from_now)
      }
      let(:product) {
        create(:simple_product, supplier_id: supplier1.id, primary_taxon: taxon,
                                properties: [property], name: "Beans")
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
            find(:link, "Shop Preferences").trigger("click")
          end

          choose "enterprise_preferred_shopfront_product_sorting_method_by_category"
          find("#s2id_enterprise_preferred_shopfront_taxon_order").click
          find(".select2-result-label", text: "Tricky Taxon").click
          click_button 'Update'
          expect(flash_message)
            .to eq('Enterprise "First Distributor" has been successfully updated!')
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
            find(:link, "Shop Preferences").trigger("click")
          end

          choose "enterprise_preferred_shopfront_product_sorting_method_by_producer"
          scroll_to(:bottom)
          find("#s2id_enterprise_preferred_shopfront_producer_order").click
          find(".select2-result-label", text: "First Supplier").click
          click_button 'Update'
          expect(flash_message)
            .to eq('Enterprise "First Distributor" has been successfully updated!')
        end

        it "sets the preference correctly" do
          expect(distributor1.preferred_shopfront_product_sorting_method).to eql("by_producer")
          expect(distributor1.preferred_shopfront_producer_order).to eql(supplier1.id.to_s)
        end
      end
    end

    describe "check users tab" do
      before do
        login_as_admin
        visit edit_admin_enterprise_path(distributor1)
        scroll_to(:bottom)
        within ".side_menu" do
          find(:link, "Users").trigger("click")
        end
      end

      context "invite user as manager" do
        before do
          expect(page).to have_selector('a', text: /Add an unregistered user/i)
          page.find('a', text: /Add an unregistered user/i).click
        end

        it "shows an error message if the email is invalid" do
          within ".reveal-modal" do
            expect(page).to have_content "Invite an unregistered user"
            fill_in "email", with: "invalid_email"

            expect do
              click_button "Invite"
              expect(page).to have_content "Email is invalid"
            end.not_to enqueue_job ActionMailer::MailDeliveryJob
          end
        end

        it "shows an error message if the email is already linked to an existing user" do
          within ".reveal-modal" do
            expect(page).to have_content "Invite an unregistered user"
            fill_in "email", with: distributor1.owner.email

            expect do
              click_button "Invite"
              expect(page).to have_content "User already exists"
            end.not_to enqueue_job ActionMailer::MailDeliveryJob
          end
        end

        it "finally, can invite unregistered users" do
          within ".reveal-modal" do
            expect(page).to have_content "Invite an unregistered user"
            fill_in "email", with: "email@email.com"

            expect do
              click_button "Invite"
              expect(page)
                .to have_content "email@email.com has been invited to manage this enterprise"
            end.to enqueue_job(ActionMailer::MailDeliveryJob).exactly(:twice)
          end
        end
      end
    end

    context "white label settings" do
      before do
        visit edit_admin_enterprise_path(distributor1)
        select_white_label
      end

      it "set the hide_ofn_navigation preference for the current shop" do
        check "Hide OFN navigation"
        click_button 'Update'
        success_message = 'Enterprise "First Distributor" has been successfully updated!'
        expect(flash_message).to eq success_message
        expect(distributor1.reload.hide_ofn_navigation).to be true

        visit edit_admin_enterprise_path(distributor1)
        select_white_label

        uncheck "Hide OFN navigation"
        click_button 'Update'
        expect(flash_message).to eq success_message
        expect(distributor1.reload.hide_ofn_navigation).to be false
      end

      it "set the hide_ofn_navigation preference for the current shop" do
        expect(page).not_to have_content "Logo used in shopfront"
        check "Hide OFN navigation"
        click_button 'Update'
        expect(flash_message)
          .to eq('Enterprise "First Distributor" has been successfully updated!')
        expect(distributor1.reload.hide_ofn_navigation).to be true

        visit edit_admin_enterprise_path(distributor1)
        select_white_label

        expect(page).to have_content "Logo used in shopfront"
        uncheck "Hide OFN navigation"
        click_button 'Update'
        expect(flash_message)
          .to eq('Enterprise "First Distributor" has been successfully updated!')
        expect(distributor1.reload.hide_ofn_navigation).to be false
      end

      context "when white label is active via `hide_ofn_navigation`" do
        before do
          distributor1.update_attribute(:hide_ofn_navigation, true)

          visit edit_admin_enterprise_path(distributor1)
          select_white_label
        end

        it "can updload the white label logo for the current shop" do
          attach_file "enterprise_white_label_logo", white_logo_path
          click_button 'Update'
          expect(flash_message)
            .to eq('Enterprise "First Distributor" has been successfully updated!')
          expect(distributor1.reload.white_label_logo_blob.filename).to eq("logo-white.png")
        end

        it "does not show the white label logo link field" do
          expect(page).not_to have_field "white_label_logo_link"
        end

        context "when enterprise has a white label logo" do
          before do
            distributor1.update white_label_logo: white_logo_file

            visit edit_admin_enterprise_path(distributor1)
            select_white_label
          end

          it "can remove the white label logo for the current shop" do
            expect(page).to have_selector("img[src*='logo-white.png']")
            expect(distributor1.white_label_logo).to be_attached
            click_button "Remove"
            within ".reveal-modal" do
              click_button "Confirm"
            end
            expect(flash_message).to match(/Logo removed/)
            distributor1.reload
            expect(distributor1.white_label_logo).not_to be_attached
          end

          shared_examples "edit link with" do |url, result|
            it "url: #{url}" do
              fill_in "enterprise_white_label_logo_link", with: url
              click_button 'Update'
              expect(flash_message)
                .to eq('Enterprise "First Distributor" has been successfully updated!')
              expect(distributor1.reload.white_label_logo_link).to eq(result)
            end
          end

          context "can edit white label logo link" do
            it_behaves_like "edit link with", "https://www.openfoodnetwork.org", "https://www.openfoodnetwork.org"
            it_behaves_like "edit link with", "www.openfoodnetwork.org", "http://www.openfoodnetwork.org"
            it_behaves_like "edit link with", "openfoodnetwork.org", "http://openfoodnetwork.org"
          end

          shared_examples "edit link with invalid" do |url|
            it "url: #{url}" do
              fill_in "enterprise_white_label_logo_link", with: url
              click_button 'Update'
              expect(page)
                .to have_content "Link for the logo used in shopfront '#{url}' is an invalid URL"
              expect(distributor1.reload.white_label_logo_link).to be_nil
            end
          end

          context "can not edit white label logo link" do
            it_behaves_like "edit link with invalid", "invalid url"
          end
        end

        it "can check/uncheck the hide_groups_tab attribute" do
          check "Hide groups tab in shopfront"
          click_button 'Update'
          expect(flash_message)
            .to eq('Enterprise "First Distributor" has been successfully updated!')
          expect(distributor1.reload.hide_groups_tab).to be true

          visit edit_admin_enterprise_path(distributor1)
          select_white_label

          uncheck "Hide groups tab in shopfront"
          click_button 'Update'
          expect(flash_message)
            .to eq('Enterprise "First Distributor" has been successfully updated!')
          expect(distributor1.reload.hide_groups_tab).to be false
        end

        context "creating custom tabs" do
          before do
            visit edit_admin_enterprise_path(distributor1)
            select_white_label
            check "Create custom tab in shopfront"
          end

          it "can save custom tab fields" do
            fill_in "enterprise_custom_tab_attributes_title", with: "Custom tab title"
            fill_in_trix_editor "custom_tab_content", with: "Custom tab content"
            click_button 'Update'
            expect(flash_message)
              .to eq('Enterprise "First Distributor" has been successfully updated!')
            expect(distributor1.reload.custom_tab.title).to eq("Custom tab title")
            expect(distributor1.reload.custom_tab.content).to eq("<div>Custom tab content</div>")
          end

          context "managing errors" do
            it "can't save custom tab fields if title is blank" do
              fill_in "enterprise_custom_tab_attributes_title", with: ""
              fill_in_trix_editor "custom_tab_content", with: "Custom tab content"
              click_button 'Update'
              expect(page).to have_content("Custom tab title can't be blank")
              expect(distributor1.reload.custom_tab).to be_nil

              select_white_label
              expect(page).to have_checked_field "Create custom tab in shopfront"
            end

            it "can't save custom tab fields if title is too long" do
              fill_in "enterprise_custom_tab_attributes_title", with: "a" * 21
              fill_in_trix_editor "custom_tab_content", with: "Custom tab content"
              click_button 'Update'
              expect(page).
                to have_content("Custom tab title is too long (maximum is 20 characters)")
              expect(distributor1.reload.custom_tab).to be_nil
            end
          end

          context "when custom tab is already created" do
            let(:custom_tab) {
              create(:custom_tab, title: "Custom tab title",
                                  content: "Custom tab content")
            }

            before do
              distributor1.update(custom_tab:)
              visit edit_admin_enterprise_path(distributor1)
              select_white_label
            end

            it "display the custom tab fields with the current values" do
              expect(page).to have_checked_field "Create custom tab in shopfront"
              expect(page).
                to have_field "enterprise_custom_tab_attributes_title", with: "Custom tab title"
              expect(page).to have_content("Custom tab content")
            end

            it "enable the update button on custom tab content change" do
              fill_in_trix_editor "custom_tab_content", with: "Custom tab content changed"
              within "save-bar" do
                expect(page).to have_button("Update", disabled: false)
              end
              expect {
                click_button 'Update'
              }.to change { distributor1.reload.custom_tab.content }
                .from("Custom tab content")
                .to("<div>Custom tab content changed</div>")
            end

            it "can delete custom tab if uncheck the checkbox" do
              uncheck "Create custom tab in shopfront"
              click_button 'Update'
              expect(flash_message)
                .to eq('Enterprise "First Distributor" has been successfully updated!')
              expect(distributor1.reload.custom_tab).to be_nil
            end
          end
        end
      end
    end
  end

  context "changing package" do
    let!(:owner) { create(:user) }
    let!(:enterprise) { create(:distributor_enterprise, owner:, is_primary_producer: true) }
    before do
      login_as owner
    end

    context "via admin path, for a producer" do
      before do
        visit spree.admin_dashboard_path
      end

      it "changes user role" do
        click_button "Change Package"

        # checks options for producer profile
        expect(page).to have_content "Producer Profile"
        expect(page).to have_content "Producer Shop"
        expect(page).to have_content "Producer Hub"
        expect(page).not_to have_content "Profile Only"
        expect(page).not_to have_content "Hub Shop"

        # Producer hub option is selected
        page.find('a', class: 'selected', text: "Producer Hub")
        expect(enterprise.reload.is_primary_producer).to eq true
        expect(enterprise.reload.sells).to eq('any')

        # Displays the correct dashboard sections
        assert_hub_menu
        assert_hub_content

        # Changes to producer shop
        page.find('a', text: "Producer Shop").click
        click_button "Change now"
        expect(page).to have_content update_message

        # Checks changes are persistent
        click_button "Change Package"

        page.find('a', class: 'selected', text: "Producer Shop")
        expect(enterprise.reload.is_primary_producer).to eq true
        expect(enterprise.reload.sells).to eq('own')

        # Displays the correct dashboard sections
        assert_hub_menu
        assert_hub_content

        # Changes to producer profile
        page.find('a', text: "Producer Profile").click
        click_button "Change now"
        expect(page).to have_content update_message

        # Checks changes are persistent
        click_button "Change Package"

        page.find('a', class: 'selected', text: "Producer Profile")

        # a primary producer:
        expect(enterprise.reload.is_primary_producer).to eq true

        # which is not selling:
        expect(enterprise.reload.sells).to eq('none')

        # then, this should imply
        # producer_profile_only to be true
        # this probably relates to issue #7835
        expect(enterprise.reload.producer_profile_only).to eq false

        # Displays the correct dashboard sections
        assert_supplier_menu
        assert_supplier_content
      end
    end

    context "via admin path, for a non-producer" do
      before do
        enterprise.update!(is_primary_producer: false)
        visit spree.admin_dashboard_path
      end

      it "changes user role" do
        click_button "Change Package"

        # checks options for non-producer profile
        expect(page).not_to have_content "Producer Profile"
        expect(page).not_to have_content "Producer Shop"
        expect(page).not_to have_content "Producer Hub"
        expect(page).to have_content "Profile Only"
        expect(page).to have_content "Hub Shop"

        # Producer hub option is selected
        page.find('a', class: 'selected', text: "Hub Shop")
        expect(enterprise.reload.is_primary_producer).to eq false
        expect(enterprise.reload.producer_profile_only).to eq false

        # Displays the correct dashboard sections
        assert_hub_menu
        assert_hub_content

        # Changes to producer shop
        page.find('a', text: "Profile Only").click
        click_button "Change now"
        expect(page).to have_content update_message

        # Checks changes are persistent
        click_button "Change Package"

        page.find('a', class: 'selected', text: "Profile Only")
        expect(enterprise.reload.is_primary_producer).to eq false
        expect(enterprise.reload.producer_profile_only).to eq false

        # Displays the correct dashboard sections
        assert_profile
      end
    end

    context "via enterprises path, for a producer" do
      before do
        visit admin_enterprises_path
      end

      it "sees and changes user role" do
        page.find("td.package").click

        # checks options for producer profile
        within ".enterprise_package_panel" do
          expect(page).to have_content "Profile Only"
          expect(page).to have_content "Producer Shop"
          expect(page).to have_content "Producer Hub"
          expect(page).not_to have_content "Hub Shop"
        end

        # Producer hub option is selected
        page.find('a', class: 'selected', text: "Producer Hub")
        expect(enterprise.is_primary_producer).to eq true
        expect(enterprise.reload.sells).to eq('any')

        # Displays the correct dashboard sections
        assert_hub_menu

        # Changes to producer shop
        page.find('a', text: "Producer Shop").click
        page.find('a', text: "SAVE").click

        # Checks changes are persistent
        page.find('a', class: 'selected', text: "Producer Shop")

        # updates page
        page.refresh

        # Displays the correct dashboard sections
        assert_hub_menu
        expect(enterprise.reload.sells).to eq('own')
        expect(enterprise.is_primary_producer).to eq true

        # Changes to producer profile
        page.find("td.package").click
        page.find('a', text: "Profile Only").click
        page.find('a', text: "SAVE").click

        # Checks changes are persistent
        page.find('a', class: 'selected', text: "Profile Only")

        # updates page
        page.refresh

        # Displays the correct dashboard sections
        assert_supplier_menu

        # a primary producer:
        expect(enterprise.reload.is_primary_producer).to eq true

        # which is not selling:
        expect(enterprise.reload.sells).to eq('none')

        # then, this should imply
        # producer_profile_only to be true
        # this probably relates to issue #7835
        expect(enterprise.reload.producer_profile_only).to eq false
      end
    end

    context "via enterprises path, for a non-producer" do
      before do
        visit admin_enterprises_path
      end

      it "sees and changes user role" do
        # changes to non-producer profile
        page.find("td.producer").click

        # checks options for producer profile
        expect(page).to have_content "Producer"
        expect(page).to have_content "Non-producer"

        # Producer hub option is selected
        page.find('a', class: 'selected', text: "Producer")
        expect(enterprise.is_primary_producer).to eq true
        expect(enterprise.reload.sells).to eq('any')

        # Changes to non-producer
        page.find('a', text: "Non-producer").click
        page.find('a', text: "SAVE").click

        # updates page
        page.refresh

        # Displays the correct dashboard sections
        assert_hub_menu

        page.find("td.package").click

        # checks options for non-producer profile
        within ".enterprise_package_panel" do
          expect(page).not_to have_content "Producer Profile"
          expect(page).not_to have_content "Producer Shop"
          expect(page).not_to have_content "Producer Hub"
          expect(page).to have_content "Profile Only"
          expect(page).to have_content "Hub Shop"
        end

        # Producer hub option is selected
        page.find('a', class: 'selected', text: "Hub Shop")
        expect(enterprise.reload.is_primary_producer).to eq false
        expect(enterprise.reload.sells).to eq('any')

        # Changes to producer shop
        page.find('a', text: "Profile Only").click
        page.find('a', text: "SAVE").click

        # updates page
        page.refresh

        # Checks changes are persistent
        page.find("td.package").click
        page.find('a', class: 'selected', text: "Profile Only")

        # Displays the correct dashboard sections
        within "#admin-menu" do
          expect(page).to have_content "Dashboard"
          expect(page).to have_content "Enterprises"
        end

        expect(enterprise.reload.is_primary_producer).to eq false
        expect(enterprise.reload.sells).to eq('none')
      end
    end
  end

  def select_white_label
    # The savebar sits on top of the bottom menu item until we scroll.
    scroll_to :bottom
    within(".side_menu") do
      click_link "White Label"
    end
  end
end

def update_message
  %(Congratulations! Registration for #{enterprise.name} is complete!)
end

def assert_hub_menu
  within "#admin-menu" do
    expect(page).to have_content "Dashboard"
    expect(page).to have_content "Products"
    expect(page).to have_content "Order cycles"
    expect(page).to have_content "Orders"
    expect(page).to have_content "Reports"
    expect(page).to have_content "Enterprises"
    expect(page).to have_content "Customers"
  end
end

def assert_hub_content
  within "#content" do
    expect(page).to have_content "Your profile live"
    expect(page).to have_content "Edit profile details"
    expect(page).to have_content "Add & manage products"
    expect(page).to have_content "Add & manage order cycles"
  end
end

def assert_supplier_menu
  within "#admin-menu" do
    expect(page).to have_content "Dashboard"
    expect(page).to have_content "Products"
    expect(page).not_to have_content "Order cycles"
    expect(page).not_to have_content "Orders"
    expect(page).to have_content "Reports"
    expect(page).to have_content "Enterprises"
    expect(page).not_to have_content "Customers"
  end
end

def assert_supplier_content
  within "#content" do
    expect(page).to have_content "Your profile live"
    expect(page).to have_content "Edit profile details"
    expect(page).to have_content "Add & manage products"
    expect(page).not_to have_content "Add & manage order cycles"
  end
end

def assert_profile
  within "#admin-menu" do
    expect(page).to have_content "Dashboard"
    expect(page).to have_content "Enterprises"
  end

  within "#content" do
    expect(page).to have_content "Your profile live"
    expect(page).to have_content "Edit profile details"
  end
end

def select_white_label
  within(".side_menu") do
    find(:link, "White Label").trigger("click")
  end
end
