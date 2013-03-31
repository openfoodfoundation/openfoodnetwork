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

  scenario "listing products" do
    p = FactoryGirl.create(:product)
    
    login_to_admin_section
    click_link 'Products'
    click_link 'Bulk Product Edit'
    
    page.first('input').value.should == p.name
  end
  
  scenario "create a new product" do
    s = FactoryGirl.create(:supplier_enterprise)
    d = FactoryGirl.create(:distributor_enterprise)
    
    login_to_admin_section
    click_link 'Products'
    click_link 'Bulk Product Edit'
    
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
    page.should have_content 'Big Bag Of Apples'
  end
  
  scenario "updating a product" do
    p = FactoryGirl.create(:product)
    s1 = FactoryGirl.create(:supplier_enterprise)
    s2 = FactoryGirl.create(:supplier_enterprise)
    p.supplier = s1
    
    login_to_admin_section
    click_link 'Products'
    click_link 'Bulk Product Edit'
    
    page.first(:css, "td select", :text => s1.name).select(s2.name)
  end
end 