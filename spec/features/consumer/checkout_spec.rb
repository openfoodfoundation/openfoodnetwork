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
    set_feature_toggle :order_cycles, true

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

    @enterprise_fee_1 = create(:enterprise_fee, :name => 'Enterprise Fee One', :calculator => Spree::Calculator::PerItem.new)
    @enterprise_fee_1.calculator.set_preference :amount, 1
    @enterprise_fee_1.calculator.save!

    @enterprise_fee_2 = create(:enterprise_fee, :name => 'Enterprise Fee Two', :calculator => Spree::Calculator::PerItem.new)
    @enterprise_fee_2.calculator.set_preference :amount, 2
    @enterprise_fee_2.calculator.save!

    @product_1 = create(:product, :name => 'Fuji apples')
    @product_1.product_distributions.create(:distributor => @distributor, :enterprise_fee => @enterprise_fee_1)
    @product_1.product_distributions.create(:distributor => @distributor_alternative, :enterprise_fee => @enterprise_fee_1)

    @product_1a = create(:product, :name => 'Sundowner apples')
    @product_1a.product_distributions.create(:distributor => @distributor, :enterprise_fee => @enterprise_fee_1)
    @product_1a.product_distributions.create(:distributor => @distributor_alternative, :enterprise_fee => @enterprise_fee_1)

    @product_2 = create(:product, :name => 'Garlic')
    @product_2.product_distributions.create(:distributor => @distributor, :enterprise_fee => @enterprise_fee_2)
    @product_2.product_distributions.create(:distributor => @distributor_alternative, :enterprise_fee => @enterprise_fee_2)

    # -- Shipping
    @zone = create(:zone)
    c = Spree::Country.find_by_name('Australia')
    Spree::ZoneMember.create(:zoneable => c, :zone => @zone)
    create(:shipping_method, zone: @zone)

    @payment_method_distributor = create(:payment_method, :name => 'Edible Garden payment method', :distributor => @distributor)
    @payment_method_alternative = create(:payment_method, :name => 'Alternative Distributor payment method', :distributor => @distributor_alternative)
  end


  scenario "viewing delivery fees for product distribution" do
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
    checkout_fees_table.should ==
      [['Product distribution by Edible garden for Fuji apples', '$1.00', ''],
       ['Product distribution by Edible garden for Garlic',      '$2.00', '']]

    page.should have_selector 'span.distribution-total', :text => '$3.00'
  end

  scenario "viewing delivery fees for order cycle distribution" do
    # Given an order cycle
    make_order_cycle

    # And I am logged in
    login_to_consumer_section

    # When I add some bananas and zucchini to my cart
    click_link 'Bananas'
    select @distributor_oc.name, :from => 'distributor_id'
    select @order_cycle.name, :from => 'order_cycle_id'
    click_button 'Add To Cart'
    click_link 'Continue shopping'

    click_link 'Zucchini'
    click_button 'Add To Cart'

    # Then I should see a breakdown of my delivery fees:
    checkout_fees_table.should ==
      [["Bananas - packing fee by supplier Supplier 1", "$3.00", ""],
       ["Bananas - transport fee by supplier Supplier 1", "$4.00", ""],
       ["Bananas - packing fee by distributor Distributor 1", "$7.00", ""],
       ["Bananas - transport fee by distributor Distributor 1", "$8.00", ""],
       ["Bananas - admin fee by coordinator My coordinator", "$1.00", ""],
       ["Bananas - sales fee by coordinator My coordinator", "$2.00", ""],
       ["Zucchini - admin fee by supplier Supplier 2", "$5.00", ""],
       ["Zucchini - sales fee by supplier Supplier 2", "$6.00", ""],
       ["Zucchini - packing fee by distributor Distributor 1", "$7.00", ""],
       ["Zucchini - transport fee by distributor Distributor 1", "$8.00", ""],
       ["Zucchini - admin fee by coordinator My coordinator", "$1.00", ""],
       ["Zucchini - sales fee by coordinator My coordinator", "$2.00", ""]]

    page.should have_selector 'span.distribution-total', :text => '$54.00'
  end

  scenario "attempting to purchase products that mix product and order cycle distribution" do
    # Given some products, one with product distribution only, (@product1)
    # one with order cycle distribution only, (@product_oc)
    supplier = create(:supplier_enterprise)
    product_oc = create(:simple_product, name: 'Feijoas')
    @order_cycle = create(:simple_order_cycle, suppliers: [supplier], distributors: [@distributor], variants: [product_oc.master])
    @order_cycle.coordinator_fees << create(:enterprise_fee, enterprise: @order_cycle.coordinator)

    # And I am logged in
    login_to_consumer_section

    # When I add the first to my cart
    click_link 'Fuji apples'
    select @distributor.name, :from => 'distributor_id'
    click_button 'Add To Cart'
    click_link 'Continue shopping'

    # And I attempt to add another
    click_link 'Feijoas'

    # Then I should see an error about changing order cycle
    page.should have_content 'Please complete your order from your current order cycle before shopping in a different order cycle.'
  end

  scenario "removing a product from cart removes its fees", js: true do
    # Given I am logged in
    login_to_consumer_section

    # When I add some apples and some garlic to my cart
    click_link 'Fuji apples'
    select @distributor.name, :from => 'distributor_id'
    click_button 'Add To Cart'
    click_link 'Continue shopping'

    click_link 'Garlic'
    click_button 'Add To Cart'

    # And I remove the applies
    line_item = Spree::Order.last.line_items.first
    page.find("a#delete_line_item_#{line_item.id}").click

    # Then I should see fees for only the garlic
    checkout_fees_table.should ==
      [['Product distribution by Edible garden for Garlic',      '$2.00', '']]

    page.should have_selector 'span.distribution-total', :text => '$2.00'
  end

  scenario "adding products with differing quantities produces correct fees" do
    # Given I am logged in
    login_to_consumer_section

    # When I add two products to my cart that share the same enterprise fee
    click_link 'Fuji apples'
    select @distributor.name, :from => 'distributor_id'
    click_button 'Add To Cart'
    click_link 'Continue shopping'

    click_link 'Sundowner apples'
    click_button 'Add To Cart'

    # Then I should have some delivery fees
    checkout_fees_table.should ==
      [['Product distribution by Edible garden for Fuji apples',      '$1.00', ''],
       ['Product distribution by Edible garden for Sundowner apples', '$1.00', '']]
    page.should have_selector 'span.distribution-total', :text => '$2.00'

    # And I update the quantity of one of them
    fill_in 'order_line_items_attributes_0_quantity', with: 2
    click_button 'Update'

    # Then I should see updated delivery fees
    checkout_fees_table.should ==
      [['Product distribution by Edible garden for Fuji apples',      '$2.00', ''],
       ['Product distribution by Edible garden for Sundowner apples', '$1.00', '']]
    page.should have_selector 'span.distribution-total', :text => '$3.00'
  end

  scenario "changing distributor updates delivery fees" do
    # Given two distributors and enterprise fees
    d1 = create(:distributor_enterprise)
    d2 = create(:distributor_enterprise)
    ef1 = create(:enterprise_fee, calculator: Spree::Calculator::PerItem.new)
    ef1.calculator.set_preference :amount, 1.23; ef1.calculator.save!
    ef2 = create(:enterprise_fee, calculator: Spree::Calculator::PerItem.new)
    ef2.calculator.set_preference :amount, 2.34; ef2.calculator.save!

    # And two products both available from both distributors
    p1 = create(:product)
    create(:product_distribution, product: p1, distributor: d1, enterprise_fee: ef1)
    create(:product_distribution, product: p1, distributor: d2, enterprise_fee: ef2)
    p2 = create(:product)
    create(:product_distribution, product: p2, distributor: d1, enterprise_fee: ef1)
    create(:product_distribution, product: p2, distributor: d2, enterprise_fee: ef2)

    # When I add the first product to my cart with the first distributor
    #visit spree.root_path
    login_to_consumer_section
    click_link p1.name
    select d1.name, :from => 'distributor_id'
    click_button 'Add To Cart'

    # Then I should see shipping costs for the first distributor
    page.should have_selector 'span.distribution-total', text: '$1.23'

    # When add the second with the second distributor
    click_link 'Continue shopping'
    click_link p2.name
    select d2.name, :from => 'distributor_id'
    click_button 'Add To Cart'

    # Then I should see shipping costs for the second distributor
    page.should have_selector 'span.distribution-total', text: '$4.68'
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
       @distributor.distributor_info,
       @distributor.next_collection_at
      ].each do |value|

        page.should have_content value
      end
    end

    # Disabled until this form takes order cycles into account
    # page.should have_selector "select#order_distributor_id option[value='#{@distributor_alternative.id}']"
    
    click_checkout_continue_button

    # -- Checkout: Delivery
    order_charges = page.all("tbody#summary-order-charges tr").map {|row| row.all('td').map(&:text)}.take(2)
    order_charges.should == [["Shipping:", "$0.00"],
                             ["Distribution:", "$3.00"]]
    click_checkout_continue_button

    # -- Checkout: Payment
    # Given the distributor I have selected for my order, I should only see payment methods valid for that distributor
    page.should have_selector     'label', :text => @payment_method_distributor.name
    page.should_not have_selector 'label', :text => @payment_method_alternative.name
    click_checkout_continue_button

    # -- Checkout: Order complete
    page.should have_content('Your order has been processed successfully')
    page.should have_content(@payment_method_all.description)


    # page.should have_content('Your order will be available on:')
    # page.should have_content('On Tuesday, 4 PM')
    # page.should have_content('12 Bungee Rd, Carion')
  end


  private

  def make_order_cycle
    @order_cycle = oc = create(:simple_order_cycle, coordinator: create(:distributor_enterprise, name: 'My coordinator'))

    # Coordinator
    coordinator_fee1 = create(:enterprise_fee, enterprise: oc.coordinator, fee_type: 'admin', amount: 1)
    coordinator_fee2 = create(:enterprise_fee, enterprise: oc.coordinator, fee_type: 'sales', amount: 2)
    oc.coordinator_fees << coordinator_fee1
    oc.coordinator_fees << coordinator_fee2

    # Suppliers
    supplier1 = create(:supplier_enterprise, name: 'Supplier 1')
    supplier2 = create(:supplier_enterprise, name: 'Supplier 2')
    supplier_fee1 = create(:enterprise_fee, enterprise: supplier1, fee_type: 'packing', amount: 3)
    supplier_fee2 = create(:enterprise_fee, enterprise: supplier1, fee_type: 'transport', amount: 4)
    supplier_fee3 = create(:enterprise_fee, enterprise: supplier2, fee_type: 'admin', amount: 5)
    supplier_fee4 = create(:enterprise_fee, enterprise: supplier2, fee_type: 'sales', amount: 6)
    ex1 = create(:exchange, order_cycle: oc, sender: supplier1, receiver: oc.coordinator)
    ex2 = create(:exchange, order_cycle: oc, sender: supplier2, receiver: oc.coordinator)
    ExchangeFee.create!(exchange: ex1, enterprise_fee: supplier_fee1)
    ExchangeFee.create!(exchange: ex1, enterprise_fee: supplier_fee2)
    ExchangeFee.create!(exchange: ex2, enterprise_fee: supplier_fee3)
    ExchangeFee.create!(exchange: ex2, enterprise_fee: supplier_fee4)

    # Distributors
    distributor1 = create(:distributor_enterprise, name: 'Distributor 1')
    distributor2 = create(:distributor_enterprise, name: 'Distributor 2')
    distributor_fee1 = create(:enterprise_fee, enterprise: distributor1, fee_type: 'packing', amount: 7)
    distributor_fee2 = create(:enterprise_fee, enterprise: distributor1, fee_type: 'transport', amount: 8)
    distributor_fee3 = create(:enterprise_fee, enterprise: distributor2, fee_type: 'admin', amount: 9)
    distributor_fee4 = create(:enterprise_fee, enterprise: distributor2, fee_type: 'sales', amount: 10)
    ex3 = create(:exchange, order_cycle: oc,
                 sender: oc.coordinator, receiver: distributor1,
                 pickup_time: 'time 0', pickup_instructions: 'instructions 0')
    ex4 = create(:exchange, order_cycle: oc,
                 sender: oc.coordinator, receiver: distributor2,
                 pickup_time: 'time 1', pickup_instructions: 'instructions 1')
    ExchangeFee.create!(exchange: ex3, enterprise_fee: distributor_fee1)
    ExchangeFee.create!(exchange: ex3, enterprise_fee: distributor_fee2)
    ExchangeFee.create!(exchange: ex4, enterprise_fee: distributor_fee3)
    ExchangeFee.create!(exchange: ex4, enterprise_fee: distributor_fee4)

    # Products
    @distributor_oc = distributor1

    @product_3 = create(:simple_product, name: 'Bananas', supplier: supplier1)
    ex1.variants << @product_3.master
    ex3.variants << @product_3.master
    ex4.variants << @product_3.master

    @product_4 = create(:simple_product, name: 'Zucchini', supplier: supplier2)
    ex2.variants << @product_4.master
    ex3.variants << @product_4.master
    ex4.variants << @product_4.master
  end

  def checkout_fees_table
    table = page.find 'tbody#cart_adjustments'
    rows = table.all 'tr'
    rows.map { |row| row.all('td').map { |cell| cell.text.strip } }
  end
end
