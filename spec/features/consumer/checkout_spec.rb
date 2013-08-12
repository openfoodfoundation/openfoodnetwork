require "spec_helper"

feature %q{
    As a consumer
    I want to select a distributor for collection
    So that I can pick up orders from the closest possible location
} do
  include AuthenticationWorkflow
  include WebHelper
  
  before :all do
    @default_wait_time = Capybara.default_wait_time
    Capybara.default_wait_time = 5
  end
  
  after :all do
    Capybara.default_wait_time = @default_wait_time
  end

  background do
    @distributor = create(:distributor_enterprise, :name => 'Edible garden',
                          :address => create(:address,
                                             :address1 => '12 Bungee Rd',
                                             :city => 'Carion',
                                             :zipcode => 3056,
                                             :state => Spree::State.find_by_name('Victoria'),
                                             :country => Spree::Country.find_by_name('Australia')),
                          :pickup_times => 'Tuesday, 4 PM')
    
    
    @distributor_alternative = create(:distributor_enterprise, :name => 'Alternative Distributor',
                          :address => create(:address,
                                             :address1 => '1600 Rathdowne St',
                                             :city => 'Carlton North',
                                             :zipcode => 3054,
                                             :state => Spree::State.find_by_name('Victoria'),
                                             :country => Spree::Country.find_by_name('Australia')),
                          :pickup_times => 'Tuesday, 4 PM')    

    @shipping_method_1 = create(:shipping_method, :name => 'Shipping Method One')
    @shipping_method_1.calculator.set_preference :amount, 1
    @shipping_method_1.calculator.save!

    @shipping_method_2 = create(:shipping_method, :name => 'Shipping Method Two')
    @shipping_method_2.calculator.set_preference :amount, 2
    @shipping_method_2.calculator.save!

    @product_1 = create(:product, :name => 'Fuji apples')
    @product_1.product_distributions.create(:distributor => @distributor, :shipping_method => @shipping_method_1)
    @product_1.product_distributions.create(:distributor => @distributor_alternative, :shipping_method => @shipping_method_1)

    @product_2 = create(:product, :name => 'Garlic')
    @product_2.product_distributions.create(:distributor => @distributor, :shipping_method => @shipping_method_2)
    @product_2.product_distributions.create(:distributor => @distributor_alternative, :shipping_method => @shipping_method_2)

    @zone = create(:zone)
    c = Spree::Country.find_by_name('Australia')
    Spree::ZoneMember.create(:zoneable => c, :zone => @zone)
    create(:itemwise_shipping_method, zone: @zone)
    create(:payment_method, :description => 'Cheque payment method')
  end


  scenario "viewing delivery fees" do
    # Given I am logged in
    login_to_consumer_section

    # When I add some apples and some garlic to my cart
    click_link 'Fuji apples'
    select @distributor.name, :from => 'distributor_id'
    click_button 'Add To Cart'
    click_link 'Continue shopping'

    click_link 'Garlic'
    click_button 'Add To Cart'

    # Then I should see a breakdown of my delivery fees:
    # Item        | Shipping Method     | Delivery Fee
    # Garlic      | Shipping Method Two | $2.00
    # Fuji apples | Shipping Method One | $1.00
    #
    # Subtotal: $3.00

    # Disabled pending spec for the new table
    # table = page.find 'table#delivery'
    # rows = table.all('tr')
    # rows[0].all('th').map { |cell| cell.text.strip }.should == ['Item',        'Shipping Method',     'Delivery Fee']
    # rows[1].all('td').map { |cell| cell.text.strip }.should == ['Fuji apples', 'Shipping Method One', '$1.00']
    # rows[2].all('td').map { |cell| cell.text.strip }.should == ['Garlic',      'Shipping Method Two', '$2.00']
    # page.should have_selector '#delivery-fees span.order-total', :text => '$3.00'
  end

  scenario "changing distributor updates delivery fees" do
    # Given two distributors and shipping methods
    d1 = create(:distributor_enterprise)
    d2 = create(:distributor_enterprise)
    sm1 = create(:shipping_method)
    sm1.calculator.set_preference :amount, 1.23; sm1.calculator.save!
    sm2 = create(:free_shipping_method)
    sm2.calculator.set_preference :amount, 2.34; sm2.calculator.save!

    # And two products both available from both distributors
    p1 = create(:product)
    create(:product_distribution, product: p1, distributor: d1, shipping_method: sm1)
    create(:product_distribution, product: p1, distributor: d2, shipping_method: sm2)
    p2 = create(:product)
    create(:product_distribution, product: p2, distributor: d1, shipping_method: sm1)
    create(:product_distribution, product: p2, distributor: d2, shipping_method: sm2)

    # When I add the first product to my cart with the first distributor
    #visit spree.root_path
    login_to_consumer_section
    click_link p1.name
    select d1.name, :from => 'distributor_id'
    click_button 'Add To Cart'

    # Then I should see shipping costs for the first distributor
    page.should have_selector 'span.shipping-total', text: '$1.23'

    # When add the second with the second distributor
    click_link 'Continue shopping'
    click_link p2.name
    select d2.name, :from => 'distributor_id'
    click_button 'Add To Cart'

    # Then I should see shipping costs for the second distributor
    page.should have_selector 'span.shipping-total', text: '$4.68'
  end

  scenario "adding a product to cart after emptying cart shows correct delivery fees" do
    # When I add a product to my cart
    login_to_consumer_section
    click_link @product_1.name
    select @distributor.name, :from => 'distributor_id'
    click_button 'Add To Cart'

    # Then I should see the correct delivery fee
    page.should have_selector 'span.grand-total', text: '$20.99'

    # When I empty my cart and add the product again
    click_button 'Empty Cart'
    click_link 'Continue shopping'
    click_link @product_1.name
    select @distributor.name, :from => 'distributor_id'
    click_button 'Add To Cart'

    # Then I should see the correct delivery fee
    page.should have_selector 'span.grand-total', text: '$20.99'
  end

  scenario "buying a product", :js => true do
    login_to_consumer_section

    click_link 'Fuji apples'
    select @distributor.name, :from => 'distributor_id'
    click_button 'Add To Cart'
    click_link 'Continue shopping'

    click_link 'Garlic'
    click_button 'Add To Cart'
    click_link 'Checkout'

    # -- Checkout: Address
    fill_in_fields('order_bill_address_attributes_firstname' => 'Joe',
                   'order_bill_address_attributes_lastname' => 'Luck',
                   'order_bill_address_attributes_address1' => '19 Sycamore Lane',
                   'order_bill_address_attributes_city' => 'Horse Hill',
                   'order_bill_address_attributes_zipcode' => '3213',
                   'order_bill_address_attributes_phone' => '12999911111')

    select('Australia', :from => 'order_bill_address_attributes_country_id')
    select('Victoria', :from => 'order_bill_address_attributes_state_id')

    # Distributor details should be displayed
    within('fieldset#shipping') do
      [@distributor.name,
       @distributor.address.address1,
       @distributor.address.city,
       @distributor.address.zipcode,
       @distributor.address.state_text,
       @distributor.address.country.name,
       @distributor.pickup_times,
       @distributor.next_collection_at,
       @distributor.contact,
       @distributor.phone,
       @distributor.email,
       @distributor.description,
       @distributor.website].each do |value|

        page.should have_content value
      end
    end

    # Disabled until this form takes order cycles into account
    # page.should have_selector "select#order_distributor_id option[value='#{@distributor_alternative.id}']"
    
    click_checkout_continue_button

    # -- Checkout: Delivery
    page.should have_selector 'label', :text => "Delivery $3.00"
    click_checkout_continue_button

    # -- Checkout: Payment
    click_checkout_continue_button

    # -- Checkout: Order complete
    page.should have_content('Your order has been processed successfully')
    page.should have_content('Cheque payment method')


    # page.should have_content('Your order will be available on:')
    # page.should have_content('On Tuesday, 4 PM')
    # page.should have_content('12 Bungee Rd, Carion')
  end
end
