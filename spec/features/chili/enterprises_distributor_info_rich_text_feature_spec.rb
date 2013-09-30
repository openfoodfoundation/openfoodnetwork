require 'spec_helper'

feature "enterprises distributor info as rich text" do
  include AuthenticationWorkflow
  include WebHelper

  before(:each) do
    OpenFoodWeb::FeatureToggle.stub(:features).and_return({eaterprises: false,
                                                           local_organics: true,
                                                           enterprises_distributor_info_rich_text: true})


    # The deployment is not set to local_organics on Rails init, so these
    # initializers won't run. Re-call them now that the deployment is set.
    EnterprisesDistributorInfoRichTextFeature::Engine.initializers.each &:run
  end


  scenario "setting distributor info as admin" do
    # Given I'm signed in as an admin
    login_to_admin_section

    # When I go to create a new enterprise
    click_link 'Enterprises'
    click_link 'New Enterprise'

    # Then I should see fields 'Profile Info' and 'Distributor Info'
    page.should have_selector 'td', text: 'Profile Info:'
    page.should have_selector 'td', text: 'Distributor Info:'

    # When I fill out the form and create the enterprise
    fill_in 'enterprise_name', :with => 'Eaterprises'
    fill_in 'enterprise_long_description', with: 'Zombie ipsum reversus ab viral inferno, nam rick grimes malum cerebro.'
    fill_in 'enterprise_distributor_info', with: 'Chu ge sai yubi dan bisento tobi ashi yubi ge omote.'
    fill_in 'enterprise_address_attributes_address1', with: '35 Ballantyne St'
    fill_in 'enterprise_address_attributes_city', with: 'Thornbury'
    fill_in 'enterprise_address_attributes_zipcode', with: '3072'
    select 'Australia', from: 'enterprise_address_attributes_country_id'
    select 'Victoria', from: 'enterprise_address_attributes_state_id'

    click_button 'Create'

    # Then I should see the enterprise details
    flash_message.should == 'Enterprise "Eaterprises" has been successfully created!'
    click_link 'Eaterprises'
    page.should have_selector "tr[data-hook='long_description'] th", text: 'Profile Info:'
    page.should have_selector "tr[data-hook='long_description'] td", text: 'Zombie ipsum reversus ab viral inferno, nam rick grimes malum cerebro.'

    page.should have_selector "tr[data-hook='distributor_info'] th", text: 'Distributor Info:'
    page.should have_selector "tr[data-hook='distributor_info'] td", text: 'Chu ge sai yubi dan bisento tobi ashi yubi ge omote.'
  end

  scenario "viewing distributor info with product distribution", js: true do
    ActionMailer::Base.deliveries.clear

    d = create(:distributor_enterprise, distributor_info: 'Chu ge sai yubi dan <strong>bisento</strong> tobi ashi yubi ge omote.', next_collection_at: 'Thursday 2nd May')
    p = create(:product, :distributors => [d])

    setup_shipping_details d

    login_to_consumer_section
    visit spree.select_distributor_order_path(d)

    # -- Product details page
    visit spree.product_path p
    within '#product-distributor-details' do
      page.should have_content 'Chu ge sai yubi dan bisento tobi ashi yubi ge omote.'
      page.should have_content 'Thursday 2nd May'
    end

    # -- Checkout
    click_button 'Add To Cart'
    click_link 'Checkout'
    within 'fieldset#shipping' do
      page.should have_content 'Chu ge sai yubi dan bisento tobi ashi yubi ge omote.'
      page.should have_content 'Thursday 2nd May'
    end

    # -- Confirmation
    complete_purchase_from_checkout_address_page
    page.should have_content 'Thursday 2nd May'

    # -- Purchase email
    wait_until { ActionMailer::Base.deliveries.length == 1 }
    email = ActionMailer::Base.deliveries.last
    email.body.should =~ /Chu ge sai yubi dan bisento tobi ashi yubi ge omote./
    email.body.should =~ /Thursday 2nd May/
  end

  scenario "viewing distributor info with order cycle distribution", js: true do
    set_feature_toggle :order_cycles, true
    ActionMailer::Base.deliveries.clear

    d = create(:distributor_enterprise, name: 'Green Grass', distributor_info: 'Chu ge sai yubi dan <strong>bisento</strong> tobi ashi yubi ge omote.', next_collection_at: 'Thursday 2nd May')
    p = create(:product)
    oc = create(:simple_order_cycle, distributors: [d], variants: [p.master])
    ex = oc.exchanges.outgoing.last
    ex = Exchange.find ex.id
    ex.pickup_time = 'Friday 4th May'
    ex.save!

    setup_shipping_details d

    login_to_consumer_section
    click_link 'Green Grass'

    # -- Product details page
    click_link p.name
    within '#product-distributor-details' do
      page.should have_content 'Chu ge sai yubi dan bisento tobi ashi yubi ge omote.'
      page.should have_content 'Friday 4th May'
    end

    # -- Checkout
    click_button 'Add To Cart'
    click_link 'Checkout'
    within 'fieldset#shipping' do
      page.should have_content 'Chu ge sai yubi dan bisento tobi ashi yubi ge omote.'
      page.should have_content 'Friday 4th May'
    end

    # -- Confirmation
    complete_purchase_from_checkout_address_page
    page.should have_content 'Friday 4th May'

    # -- Purchase email
    wait_until { ActionMailer::Base.deliveries.length == 1 }
    email = ActionMailer::Base.deliveries.last
    email.body.should =~ /Chu ge sai yubi dan bisento tobi ashi yubi ge omote./
    email.body.should =~ /Friday 4th May/
  end


  private
  def setup_shipping_details(distributor)
    zone = create(:zone)
    c = Spree::Country.find_by_name('Australia')
    Spree::ZoneMember.create(:zoneable => c, :zone => zone)
    create(:shipping_method, zone: zone)
    create(:payment_method, :description => 'Cheque payment method', distributors: [distributor])
  end


  def complete_purchase_from_checkout_address_page
    fill_in_fields('order_bill_address_attributes_firstname' => 'Joe',
                   'order_bill_address_attributes_lastname' => 'Luck',
                   'order_bill_address_attributes_address1' => '19 Sycamore Lane',
                   'order_bill_address_attributes_city' => 'Horse Hill',
                   'order_bill_address_attributes_zipcode' => '3213',
                   'order_bill_address_attributes_phone' => '12999911111')

    select('Australia', :from => 'order_bill_address_attributes_country_id')
    select('Victoria', :from => 'order_bill_address_attributes_state_id')

    click_checkout_continue_button
    click_checkout_continue_button
    click_checkout_continue_button
  end
end
