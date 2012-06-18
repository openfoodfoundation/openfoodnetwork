require "spec_helper"

feature %q{
    As a consumer
    I want select a distributor for collection
    So that I can pick up orders from the closest possible location
} do
  include AuthenticationWorkflow
  include WebHelper

  background do
    @distributor1 = Spree::Distributor.make!(:name => 'Eaterprises')
    @distributor2 = Spree::Distributor.make!(:name => 'Edible garden',
      :pickup_address => '12 Bungee Rd',
      :city => 'Carion',
      :pickup_times => 'Tuesday, 4 PM')
    @product = Spree::Product.make!(:name => 'Fuji apples')

    @zone = Spree::Zone.make!
    Spree::ZoneMember.create(zone: @zone, zoneable: Spree::Country.find_by_name('Australia'))
    Spree::ShippingMethod.make!(zone: @zone)
    Spree::PaymentMethod.make!
  end

  context "Given I am buying a product", :js => true do
    scenario "I should be able choose a distributor to pick up from", :skip => true do
      login_to_consumer_section

      click_link 'Fuji apples'
      click_button 'Add To Cart'
      click_link 'Checkout'

      fill_in_fields('order_bill_address_attributes_firstname' => 'Joe',
        'order_bill_address_attributes_lastname' => 'Luck',
        'order_bill_address_attributes_address1' => '19 Sycamore Lane',
        'order_bill_address_attributes_city' => 'Horse Hill',
        'order_bill_address_attributes_zipcode' => '3213',
        'order_bill_address_attributes_phone' => '12999911111')


      select('Australia', :from => 'order_bill_address_attributes_country_id')
      select('Victoria', :from => 'order_bill_address_attributes_state_id')

      select('Edible garden', :from => 'order_distributor_id')

      # within('.distributor-details') do
      #   page.should have_content('12 Bungee Rd')
      #   page.should have_content('Carion')
      #   page.should have_content('Tuesday, 4 PM')
      # end

      click_button 'Save and Continue'
      #display delivery details?

      click_button 'Save and Continue'
      fill_in 'card_number', :with => '4111111111111111'
      select('1', :from => 'payment_source_1_month')
      select("#{DateTime.now.year + 1}", :from => 'payment_source_1_year')
      fill_in 'card_code', :with => '234'

      click_button 'Save and Continue'

      page.should have_content('Your order has been processed successfully')
      # page.should have_content('Your order will be available on:')
      # page.should have_content('On Tuesday, 4 PM')
      # page.should have_content('12 Bungee Rd, Carion')
    end
  end

end
