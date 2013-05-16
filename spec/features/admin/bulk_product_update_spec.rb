require 'spec_helper'

feature %q{
  As an Administrator
  I want to be able to manage products in bulk
} , js: true do
  include AuthenticationWorkflow
  include WebHelper
  
  before :all do
    @default_wait_time = Capybara.default_wait_time
    Capybara.default_wait_time = 5
  end
  
  after :all do
    Capybara.default_wait_time = @default_wait_time
  end

  describe "listing products" do
    before :each do
      login_to_admin_section
    end

    it "displays a list of products" do
      p1 = FactoryGirl.create(:product)
      p2 = FactoryGirl.create(:product)

      visit '/admin/products/bulk_index'

      page.should have_field "product_name", with: p1.name
      page.should have_field "product_name", with: p2.name
    end

    it "displays a select box for suppliers, with the appropriate supplier selected" do
      s1 = FactoryGirl.create(:supplier_enterprise)
      s2 = FactoryGirl.create(:supplier_enterprise)
      s3 = FactoryGirl.create(:supplier_enterprise)
      p1 = FactoryGirl.create(:product, supplier: s2)
      p2 = FactoryGirl.create(:product, supplier: s3)

      visit '/admin/products/bulk_index'

      page.should have_select "supplier_id", with_options: [s1.name,s2.name,s3.name], selected: s2.name
      page.should have_select "supplier_id", with_options: [s1.name,s2.name,s3.name], selected: s3.name
    end
    
    it "displays a date input for available_on for each product, formatted to yyyy-mm-dd hh:mm:ss" do
      p1 = FactoryGirl.create(:product, available_on: Date.today)
      p2 = FactoryGirl.create(:product, available_on: Date.today-1)

      visit '/admin/products/bulk_index'

      page.should have_field "available_on", with: p1.available_on.strftime("%F %T")
      page.should have_field "available_on", with: p2.available_on.strftime("%F %T")
    end
  end
  
  scenario "create a new product" do
    s = FactoryGirl.create(:supplier_enterprise)
    d = FactoryGirl.create(:distributor_enterprise)

    login_to_admin_section

    visit '/admin/products/bulk_index'

    click_link 'New Product'

    page.should have_content 'NEW PRODUCT'

    fill_in 'product_name', :with => 'Big Bag Of Apples'
    select(s.name, :from => 'product_supplier_id')
    choose('product_group_buy_0')
    fill_in 'product_price', :with => '10.00'
    fill_in 'product_available_on', :with => Date.today.strftime("%Y/%m/%d")
    check('product_product_distributions_attributes_0__destroy')
    click_button 'Create'

    URI.parse(current_url).path.should == '/admin/products/bulk_index'
    flash_message.should == 'Product "Big Bag Of Apples" has been successfully created!'
    page.should have_field "product_name", with: 'Big Bag Of Apples'
  end
  
  
  scenario "updating a product" do
    s1 = FactoryGirl.create(:supplier_enterprise)
    s2 = FactoryGirl.create(:supplier_enterprise)
    p = FactoryGirl.create(:product, supplier: s1, available_on: Date.today)
    
    login_to_admin_section

    visit '/admin/products/bulk_index'

    page.should have_field "product_name", with: p.name
    page.should have_select "supplier_id", selected: s1.name
    page.should have_field "available_on", with: p.available_on.strftime("%F %T")

    fill_in "product_name", with: "Big Bag Of Potatoes"
    select(s2.name, :from => 'supplier_id')
    fill_in "available_on", with: (Date.today-3).strftime("%F %T")

    click_button 'Update'
    page.find("span#update-status-message").should have_content "Update complete"

    visit '/admin/products/bulk_index'

    page.should have_field "product_name", with: "Big Bag Of Potatoes"
    page.should have_select "supplier_id", selected: s2.name
    page.should have_field "available_on", with: (Date.today-3).strftime("%F %T")
  end
end 