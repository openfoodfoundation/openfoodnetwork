require "spec_helper"

feature %q{
    As an administrator
    I want numbers, all the numbers!
} do
  include AuthenticationWorkflow
  include WebHelper


  scenario "orders and distributors report" do
    login_to_admin_section
    click_link 'Reports'
    click_link 'Orders And Distributors'

    page.should have_content 'Order date'
  end

  scenario "group buys report" do
    login_to_admin_section
    click_link 'Reports'
    click_link 'Group Buys'

    page.should have_content 'Supplier'
  end

  scenario "bulk co-op report" do
    login_to_admin_section
    click_link 'Reports'
    click_link 'Bulk Co-Op'

    page.should have_content 'Supplier'
  end

  scenario "payments reports" do
    login_to_admin_section
    click_link 'Reports'
    click_link 'Payment Reports'

    page.should have_content 'Payment State'
  end

  scenario "order cycle reports" do
    login_to_admin_section
    click_link 'Reports'
    click_link 'Order Cycle Reports'

    page.should have_content 'Supplier'
  end

  scenario "order cycle reports are precise to time of day, not just date" do
    # Given two orders on the same day at different times
    @bill_address = create(:address)
    @distributor_address = create(:address, :address1 => "distributor address", :city => 'The Shire', :zipcode => "1234")
    @distributor = create(:distributor_enterprise, :address => @distributor_address)
    product = create(:product)
    product_distribution = create(:product_distribution, :product => product, :distributor => @distributor)
    @shipping_instructions = "pick up on thursday please!"
    @order1 = create(:order, :distributor => @distributor, :bill_address => @bill_address, :special_instructions => @shipping_instructions)
    @order2 = create(:order, :distributor => @distributor, :bill_address => @bill_address, :special_instructions => @shipping_instructions)

    Timecop.travel(Time.zone.local(2013, 4, 25, 14, 0, 0)) { @order1.finalize! }
    Timecop.travel(Time.zone.local(2013, 4, 25, 16, 0, 0)) { @order2.finalize! }

    create(:line_item, :product => product, :order => @order1)
    create(:line_item, :product => product, :order => @order2)

    # When I generate a customer report with a timeframe that includes one order but not the other
    login_to_admin_section
    click_link 'Reports'
    click_link 'Order Cycle Reports'

    fill_in 'q_completed_at_gt', with: '2013-04-25 13:00:00'
    fill_in 'q_completed_at_lt', with: '2013-04-25 15:00:00'
    select 'Order Cycle Customer Totals', from: 'report_type'
    click_button 'Search'

    # Then I should see the rows for the first order but not the second
    all('table#listing_orders tbody tr').count.should == 2 # Two rows per order
  end

  scenario "Order cycle reports show only the selected order cycle" do
    # Given two orders for two order cycles
    @bill_address = create(:address)
    @distributor_address = create(:address, :address1 => "distributor address", :city => 'The Shire', :zipcode => "1234")
    d1 = create(:distributor_enterprise, :address => @distributor_address)
    p1 = create(:product, price: 12.34)
    p2 = create(:product, price: 23.45)
    product_distribution = create(:product_distribution, :product => p1, :distributor => d1)
    product_distribution = create(:product_distribution, :product => p2, :distributor => d1)
    @shipping_instructions = "pick up on thursday please!"

    oc1 = create(:order_cycle, :distributors => [d1], :variants => [p1.master])
    oc2 = create(:order_cycle, :distributors => [d1], :variants => [p2.master])

    # Given each order has one product, p1 for oc1; p2 for oc2
    @order11 = create(:order, :distributor => d1, :bill_address => @bill_address, :special_instructions => @shipping_instructions, :order_cycle => oc1)
    @order12 = create(:order, :distributor => d1, :bill_address => @bill_address, :special_instructions => @shipping_instructions, :order_cycle => oc1)
    @order21 = create(:order, :distributor => d1, :bill_address => @bill_address, :special_instructions => @shipping_instructions, :order_cycle => oc2)
    @order22 = create(:order, :distributor => d1, :bill_address => @bill_address, :special_instructions => @shipping_instructions, :order_cycle => oc2)

    @order11.line_items << create(:line_item, variant: p1.master)
    @order12.line_items << create(:line_item, variant: p1.master)
    @order21.line_items << create(:line_item, variant: p2.master)
    @order22.line_items << create(:line_item, variant: p2.master)

    @order11.finalize!
    @order12.finalize!
    @order21.finalize!
    @order21.finalize!

    # When I select one order cycle
    login_to_admin_section
    click_link 'Reports'
    click_link 'Order Cycle Reports'

    select oc1.name, from: 'q_order_cycle_id_eq'
    select 'Order Cycle Supplier Totals', from: 'report_type'
    click_button 'Search'

    # Then I should see the rows for order cycle 1 but not order cycle 2
    all('table#listing_orders tbody tr').count.should == 1 # One row per product
    page.should have_content p1.price.to_s
    page.should_not have_content p2.price.to_s
  end


end
