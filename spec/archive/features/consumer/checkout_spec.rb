require "spec_helper"

feature %q{
    As a consumer
    I want to select a distributor for collection
    So that I can pick up orders from the closest possible location
}, skip: true do
  include AuthenticationWorkflow
  include WebHelper


  background do
    set_feature_toggle :order_cycles, true

    Spree::Product.destroy_all
    Spree::Order.destroy_all
    Spree::LineItem.destroy_all

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
    sm = create(:shipping_method, zone: @zone, calculator: Spree::Calculator::FlatRate.new, require_ship_address: false)
    sm.calculator.set_preference(:amount, 0); sm.calculator.save!

    @payment_method_distributor = create(:payment_method, :name => 'Edible Garden payment method', :distributors => [@distributor])
    @payment_method_alternative = create(:payment_method, :name => 'Alternative Distributor payment method', :distributors => [@distributor_alternative])

    supplier = create(:supplier_enterprise)
    @order_cycle = create(:simple_order_cycle, suppliers: [supplier], distributors: [@distributor], variants: [@product_1.master, @product_1a.master, @product_2.master])
    @order_cycle.coordinator_fees << create(:enterprise_fee, enterprise: @order_cycle.coordinator)
  end


  scenario "viewing delivery fees for product distribution", :js => true, :to_figure_out => true do
    # Given I am logged in
    login_to_consumer_section
    click_link 'Edible garden'

    make_order_cycle

    select_by_value @order_cycle.id, :from => 'order_order_cycle_id'

    # When I add some apples and some garlic to my cart
    click_link 'Fuji apples'
    click_button 'Add To Cart'
    visit enterprise_path @distributor1

    click_link 'Garlic'
    click_button 'Add To Cart'

    # Then I should see a breakdown of my delivery fees:
    checkout_fees_table.should ==
      [['Fuji apples - sales fee by coordinator Edible garden', '$1.00', ''],
       ['Garlic - sales fee by coordinator Edible garden', '$1.00', '']]

    page.should have_selector 'span.distribution-total', :text => '$2.00'
  end

  scenario "viewing delivery fees for order cycle distribution", :js => true do
    # Given an order cycle
    make_order_cycle

    # And I am logged in
    login_to_consumer_section
    click_link "FruitAndVeg"
    visit enterprise_path @distributor1

    # When I add some bananas and zucchini to my cart
    click_link 'Bananas'
    click_button 'Add To Cart'
    visit enterprise_path @distributor1

    click_link 'Zucchini'
    click_button 'Add To Cart'

    # Then I should see a breakdown of my delivery fees:

    checkout_fees_table.should ==
      [["Bananas - packing fee by supplier Supplier 1", "$3.00", ""],
       ["Bananas - transport fee by supplier Supplier 1", "$4.00", ""],
       ["Bananas - packing fee by distributor FruitAndVeg", "$7.00", ""],
       ["Bananas - transport fee by distributor FruitAndVeg", "$8.00", ""],
       ["Zucchini - admin fee by supplier Supplier 2", "$5.00", ""],
       ["Zucchini - sales fee by supplier Supplier 2", "$6.00", ""],
       ["Zucchini - packing fee by distributor FruitAndVeg", "$7.00", ""],
       ["Zucchini - transport fee by distributor FruitAndVeg", "$8.00", ""],
       ["Whole order - admin fee by coordinator My coordinator", "$1.00", ""],
       ["Whole order - sales fee by coordinator My coordinator", "$2.00", ""]]

    page.should have_selector 'span.distribution-total', :text => '$51.00'
  end

  scenario "attempting to purchase products that mix product and order cycle distribution", future: true do
    # Given some products, one with product distribution only, (@product1)
    # one with order cycle distribution only, (@product_oc)
    supplier = create(:supplier_enterprise)
    product_oc = create(:simple_product, name: 'Feijoas')
    @order_cycle = create(:simple_order_cycle, suppliers: [supplier], distributors: [@distributor], variants: [product_oc.master], orders_close_at: Time.zone.now + 2.weeks)
    @order_cycle.coordinator_fees << create(:enterprise_fee, enterprise: @order_cycle.coordinator)

    # And I am logged in
    login_to_consumer_section
    click_link "Edible garden"

    select_by_value @order_cycle.id, :from => 'order_order_cycle_id'

    # When I add the first to my cart
    click_link 'Fuji apples'
    click_button 'Add To Cart'
    click_link 'Continue shopping'

    # And I attempt to add another
    click_link 'Feijoas'

    # Then I should see an error about changing order cycle
    page.should have_content 'Please complete your order from your current order cycle before shopping in a different order cycle.'
  end

  scenario "removing a product from cart removes its fees", js: true, to_figure_out: true do
    # Given I am logged in
    login_to_consumer_section
    click_link "Edible garden"

    select_by_value @order_cycle.id, :from => 'order_order_cycle_id'

    # When I add some apples and some garlic to my cart
    click_link 'Fuji apples'
    click_button 'Add To Cart'
    click_link 'Continue shopping'

    click_link 'Garlic'
    click_button 'Add To Cart'

    # And I remove the applies
    line_item = Spree::Order.last.line_items.first
    page.find("a#delete_line_item_#{line_item.id}").click

    # Then I should see fees for only the garlic
    checkout_fees_table.should ==

      [['Garlic - transport fee by coordinator Edible garden', '$3.00', '']]

    page.should have_selector 'span.distribution-total', :text => '$3.00'
  end

  scenario "adding products with differing quantities produces correct fees", js: true, :to_figure_out => true do
    # Given I am logged in
    login_to_consumer_section
    click_link "Edible garden"

    select_by_value @order_cycle.id, :from => 'order_order_cycle_id'

    # When I add two products to my cart that share the same enterprise fee
    click_link 'Fuji apples'
    click_button 'Add To Cart'
    click_link 'Continue shopping'

    click_link 'Sundowner apples'
    click_button 'Add To Cart'

    # Then I should have some delivery fees
    checkout_fees_table.should ==
      [['Fuji apples - packing fee by coordinator Edible garden', '$4.00', ''],
       ['Sundowner apples - packing fee by coordinator Edible garden', '$4.00', '']]

    page.should have_selector 'span.distribution-total', :text => '$8.00'

    # And I update the quantity of one of them
    fill_in 'order_line_items_attributes_0_quantity', with: 2
    click_button 'Update'

    # Then I should see updated delivery fees
    checkout_fees_table.should ==
      [['Fuji apples - packing fee by coordinator Edible garden', '$8.00', ''],
       ['Sundowner apples - packing fee by coordinator Edible garden', '$4.00', '']]

    page.should have_selector 'span.distribution-total', :text => '$12.00'
  end

  scenario "changing distributor updates delivery fees", :future => true do
    # Given two distributors and enterprise fees
    d1 = create(:distributor_enterprise, :name => "FruitAndVeg")
    create_enterprise_group_for d1
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
    click_link "FruitAndVeg"
    click_link p1.name
    click_button 'Add To Cart'

    # Then I should see shipping costs for the first distributor
    page.should have_selector 'span.distribution-total', text: '$1.23'

    # When add the second with the second distributor
    click_link 'Continue shopping'
    click_link p2.name
    click_button 'Add To Cart'

    # Then I should see shipping costs for the second distributor
    page.should have_selector 'span.distribution-total', text: '$4.68'
  end

  scenario "adding a product to cart after emptying cart shows correct delivery fees", js: true, :to_figure_out => true do
    # When I add a product to my cart
    login_to_consumer_section
    click_link "Edible garden"

    select_by_value @order_cycle.id, :from => 'order_order_cycle_id'

    click_link @product_1.name
    click_button 'Add To Cart'

    # Then I should see the correct delivery fee
    page.should have_selector 'span.grand-total', text: '$24.99'

    # When I empty my cart and add the product again
    click_button 'Empty Cart'
    click_link 'Continue shopping'
    click_link @product_1.name
    click_button 'Add To Cart'

    # Then I should see the correct delivery fee
    page.should have_selector 'span.grand-total', text: '$24.99'
  end

  scenario "buying a product", :js => true, :to_figure_out => true do
    login_to_consumer_section
    click_link 'Edible garden'

    select_by_value @order_cycle.id, :from => 'order_order_cycle_id'

    click_link 'Fuji apples'
    click_button 'Add To Cart'
    click_link 'Continue shopping'

    click_link 'Garlic'
    click_button 'Add To Cart'
    find('#checkout-link').click

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
                             ["Distribution:", "$12.00"]]
    click_checkout_continue_button

    # -- Checkout: Payment
    # Given the distributor I have selected for my order, I should only see payment methods valid for that distributor
    page.should have_selector     'label', :text => @payment_method_distributor.name
    page.should_not have_selector 'label', :text => @payment_method_alternative.name
    click_checkout_continue_button

    # -- Checkout: Order complete
    page.should have_content 'Your order has been processed successfully'
    page.should have_content @payment_method_distributor.description

    page.should have_selector 'tfoot#order-charges tr.total td', text: 'Distribution'
    page.should have_selector 'tfoot#order-charges tr.total td', text: '12.00'

    # -- Checkout: Email
    email = ActionMailer::Base.deliveries.last
    email.body.should =~ /Distribution[\s+]\$12.00/
  end

  scenario "buying a product from an order cycle", :js => true do
    make_order_cycle

    login_to_consumer_section
    click_link 'FruitAndVeg'
    visit enterprise_path @distributor1

    click_link 'Bananas'
    click_button 'Add To Cart'
    visit enterprise_path @distributor1

    click_link 'Zucchini'
    click_button 'Add To Cart'
    find('#checkout-link').click

    # And manually visit the old checkout
    visit "/checkout"

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
      [@distributor_oc.name,
       @distributor_oc.distributor_info,
       @distributor_oc.next_collection_at
      ].each do |value|

        page.should have_content value
      end
    end

    # Disabled until this form takes order cycles into account
    # page.should have_selector "select#order_distributor_id option[value='#{@distributor_alternative.id}']"
    click_checkout_continue_button

    # -- Checkout: Delivery
    page.should have_content "DELIVERY METHOD"
    order_charges = page.all("tbody#summary-order-charges tr").map {|row| row.all('td').map(&:text)}.take(2)
    order_charges.should == [["Distribution:", "$51.00"]]

    click_checkout_continue_button

    # -- Checkout: Payment
    # Given the distributor I have selected for my order, I should only see payment methods valid for that distributor
    page.should have_content "PAYMENT INFORMATION"
    page.should have_selector     'label', :text => @payment_method_distributor_oc.name
    page.should_not have_selector 'label', :text => @payment_method_alternative.name
    click_checkout_continue_button

    # -- Checkout: Order complete
    page.should have_content 'Your order has been processed successfully'
    page.should have_content @payment_method_distributor_oc.description
    page.should have_content @distributor_oc.name

    page.should have_selector 'tfoot#order-charges tr.total td', text: 'Distribution'
    page.should have_selector 'tfoot#order-charges tr.total td', text: '51.00'


    # -- Checkout: Email
    email = ActionMailer::Base.deliveries.last
    email.reply_to.include?(@distributor_oc.email).should == true
    email.body.should =~ /Distribution[\s+]\$51.00/
  end

  scenario "when I have past orders, it fills in my address", :js => true do
    make_order_cycle

    login_to_consumer_section

    user = Spree::User.find_by_email 'someone@ofn.org'
    o = create(:completed_order_with_totals, user: user,
               bill_address: create(:address, firstname: 'Joe', lastname: 'Luck',
                                    address1: '19 Sycamore Lane', city: 'Horse Hill',
                                    zipcode: '3213', phone: '12999911111',
                                    state: Spree::State.find_by_name('Victoria'),
                                    country: Spree::Country.find_by_name('Australia')))

    click_link 'FruitAndVeg'
    click_link 'Sign Out'
    click_link 'FruitAndVeg'
    visit enterprise_path @distributor1

    click_link 'Bananas'
    click_button 'Add To Cart'
    visit enterprise_path @distributor1

    click_link 'Zucchini'
    click_button 'Add To Cart'
    find('#checkout-link').click
    visit "/checkout" # Force to old checkout

    # -- Login
    # We perform login inline because:
    # a) It's a common user flow
    # b) It has been known to trigger errors with spree_last_address
    fill_in 'spree_user_email', :with => 'someone@ofn.org'
    fill_in 'spree_user_password', :with => 'passw0rd'
    click_button 'Login'
    visit "/checkout" # Force to old checkout

    # -- Checkout: Address
    page.should have_field 'order_bill_address_attributes_firstname', with: 'Joe'
    page.should have_field 'order_bill_address_attributes_lastname', with: 'Luck'
    page.should have_field 'order_bill_address_attributes_address1', with: '19 Sycamore Lane'
    page.should have_field 'order_bill_address_attributes_city', with: 'Horse Hill'
    page.should have_field 'order_bill_address_attributes_zipcode', with: '3213'
    page.should have_field 'order_bill_address_attributes_phone', with: '12999911111'
    page.should have_select 'order_bill_address_attributes_state_id', selected: 'Victoria'
    page.should have_select 'order_bill_address_attributes_country_id', selected: 'Australia'
  end


  private

  def make_order_cycle
    @order_cycle = oc = create(:simple_order_cycle, coordinator: create(:distributor_enterprise, name: 'My coordinator'))

    # Coordinator
    coordinator_fee1 = create(:enterprise_fee, enterprise: oc.coordinator, fee_type: 'admin', calculator: Spree::Calculator::FlatRate.new(preferred_amount: 1))
    coordinator_fee2 = create(:enterprise_fee, enterprise: oc.coordinator, fee_type: 'sales', calculator: Spree::Calculator::FlatRate.new(preferred_amount: 2))
    oc.coordinator_fees << coordinator_fee1
    oc.coordinator_fees << coordinator_fee2

    # Suppliers
    supplier1 = create(:supplier_enterprise, name: 'Supplier 1')
    supplier2 = create(:supplier_enterprise, name: 'Supplier 2')
    supplier_fee1 = create(:enterprise_fee, enterprise: supplier1, fee_type: 'packing', amount: 3)
    supplier_fee2 = create(:enterprise_fee, enterprise: supplier1, fee_type: 'transport', amount: 4)
    supplier_fee3 = create(:enterprise_fee, enterprise: supplier2, fee_type: 'admin', amount: 5)
    supplier_fee4 = create(:enterprise_fee, enterprise: supplier2, fee_type: 'sales', amount: 6)
    ex1 = create(:exchange, order_cycle: oc, sender: supplier1, receiver: oc.coordinator, incoming: true)
    ex2 = create(:exchange, order_cycle: oc, sender: supplier2, receiver: oc.coordinator, incoming: true)
    ExchangeFee.create!(exchange: ex1, enterprise_fee: supplier_fee1)
    ExchangeFee.create!(exchange: ex1, enterprise_fee: supplier_fee2)
    ExchangeFee.create!(exchange: ex2, enterprise_fee: supplier_fee3)
    ExchangeFee.create!(exchange: ex2, enterprise_fee: supplier_fee4)

    # Distributors
    distributor1 = FactoryGirl.create(:distributor_enterprise, name: "FruitAndVeg")
    @distributor1 = distributor1
    distributor2 = FactoryGirl.create(:distributor_enterprise, name: "MoreFreshStuff")
    create_enterprise_group_for distributor1
    distributor_fee1 = create(:enterprise_fee, enterprise: distributor1, fee_type: 'packing', amount: 7)
    distributor_fee2 = create(:enterprise_fee, enterprise: distributor1, fee_type: 'transport', amount: 8)
    distributor_fee3 = create(:enterprise_fee, enterprise: distributor2, fee_type: 'admin', amount: 9)
    distributor_fee4 = create(:enterprise_fee, enterprise: distributor2, fee_type: 'sales', amount: 10)
    ex3 = create(:exchange, order_cycle: oc, incoming: false,
                 sender: oc.coordinator, receiver: distributor1,
                 pickup_time: 'time 0', pickup_instructions: 'instructions 0')
    ex4 = create(:exchange, order_cycle: oc, incoming: false,
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

    # Shipping method and payment method
    sm = create(:shipping_method, zone: @zone, calculator: Spree::Calculator::FlatRate.new, distributors: [@distributor_oc], require_ship_address: false)
    sm.calculator.set_preference(:amount, 0); sm.calculator.save!
    @payment_method_distributor_oc = create(:payment_method, :name => 'FruitAndVeg payment method', :distributors => [@distributor_oc])
  end

  def checkout_fees_table
    table = page.find 'tbody#cart_adjustments'
    rows = table.all 'tr'
    rows.map { |row| row.all('td').map { |cell| cell.text.strip } }
  end
end
