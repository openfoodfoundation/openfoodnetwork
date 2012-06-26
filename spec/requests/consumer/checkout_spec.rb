require "spec_helper"

feature %q{
    As a consumer
    I want select a distributor for collection
    So that I can pick up orders from the closest possible location
} do
  include AuthenticationWorkflow
  include WebHelper

  background do
    @distributor = create(:distributor, :name => 'Edible garden',
                          :pickup_address => create(:address,
                                                    :address1 => '12 Bungee Rd',
                                                    :city => 'Carion',
                                                    :zipcode => 3056,
                                                    :state => Spree::State.find_by_name('Victoria'),
                                                    :country => Spree::Country.find_by_name('Australia')),
                          :pickup_times => 'Tuesday, 4 PM')
    @product = create(:product, :name => 'Fuji apples', :distributors => [@distributor])

    @zone = create(:zone)
    c = Spree::Country.find_by_name('Australia')
    Spree::ZoneMember.create(:zoneable => c, :zone => @zone)
    create(:shipping_method, zone: @zone)
    create(:payment_method)
  end


  scenario "buying a product", :js => true do
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

    within('fieldset#shipping') do
      [@distributor.name,
       @distributor.pickup_address.address1,
       @distributor.pickup_address.city,
       @distributor.pickup_address.zipcode,
       @distributor.pickup_address.state_text,
       @distributor.pickup_address.country.name,
       @distributor.pickup_times,
       @distributor.contact,
       @distributor.phone,
       @distributor.email,
       @distributor.description,
       @distributor.url].each do |value|

        page.should have_content value
      end
    end

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
