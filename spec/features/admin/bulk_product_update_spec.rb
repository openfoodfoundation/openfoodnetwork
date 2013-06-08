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

    it "displays a select box for suppliers,  with the appropriate supplier selected" do
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

    it "displays a price input for each product (ie. for master variant)" do
      p1 = FactoryGirl.create(:product)
      p2 = FactoryGirl.create(:product)
      p1.price = 22.00
      p2.price = 44.00
      p1.save!
      p2.save!

      visit '/admin/products/bulk_index'

      page.should have_field "price", with: "22.0"
      page.should have_field "price", with: "44.0"
    end
    
    it "displays an on hand count input for each product (ie. for master variant) if no regular variants exist" do
      p1 = FactoryGirl.create(:product)
      p2 = FactoryGirl.create(:product)
      p1.on_hand = 15
      p2.on_hand = 12
      p1.save!
      p2.save!

      visit '/admin/products/bulk_index'

      page.should_not have_selector "span[name='on_hand']", text: "0"
      page.should have_field "on_hand", with: "15"
      page.should have_field "on_hand", with: "12"
    end
    
    it "displays an on hand count in a span for each product (ie. for master variant) if other variants exist" do
      p1 = FactoryGirl.create(:product)
      p2 = FactoryGirl.create(:product)
      v1 = FactoryGirl.create(:variant, product: p1, is_master: false, on_hand: 4)
      p1.on_hand = 15
      p2.on_hand = 12
      p1.save!
      p2.save!

      visit '/admin/products/bulk_index'

      page.should_not have_field "on_hand", with: "15"
      page.should have_selector "span[name='on_hand']", text: "4"
      page.should have_field "on_hand", with: "12"
    end
  end
  
  describe "listing variants" do
    before :each do
      login_to_admin_section
    end

    it "displays a list of variants for each product" do
      v1 = FactoryGirl.create(:variant)
      v2 = FactoryGirl.create(:variant)

      visit '/admin/products/bulk_index'

      page.should have_field "product_name", with: v1.product.name
      page.should have_field "product_name", with: v2.product.name
      page.should have_selector "td", text: v1.options_text
      page.should have_selector "td", text: v2.options_text
    end

    it "displays an on_hand input (for each variant) for each product" do
      p1 = FactoryGirl.create(:product)
      v1 = FactoryGirl.create(:variant, product: p1, is_master: false, on_hand: 15)
      v2 = FactoryGirl.create(:variant, product: p1, is_master: false, on_hand: 6)

      visit '/admin/products/bulk_index'

      page.should have_selector "span[name='on_hand']", text: "21"
      page.should have_field "variant_on_hand", with: "15"
      page.should have_field "variant_on_hand", with: "6"
    end
    
   
    it "displays a price input (for each variant) for each product" do
      p1 = FactoryGirl.create(:product, price: 2.0)
      v1 = FactoryGirl.create(:variant, product: p1, is_master: false, price: 12.75)
      v2 = FactoryGirl.create(:variant, product: p1, is_master: false, price: 2.50)

      visit '/admin/products/bulk_index'

      page.should have_field "price", with: "2.0"
      page.should have_field "variant_price", with: "12.75"
      page.should have_field "variant_price", with: "2.5"
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

  scenario "updating a product with no variants (except master)" do
    s1 = FactoryGirl.create(:supplier_enterprise)
    s2 = FactoryGirl.create(:supplier_enterprise)
    p = FactoryGirl.create(:product, supplier: s1, available_on: Date.today)
    p.price = 10.0
    p.on_hand = 6;
    p.save!

    login_to_admin_section

    visit '/admin/products/bulk_index'

    page.should have_field "product_name", with: p.name
    page.should have_select "supplier_id", selected: s1.name
    page.should have_field "available_on", with: p.available_on.strftime("%F %T")
    page.should have_field "price", with: "10.0"
    page.should have_field "on_hand", with: "6"

    fill_in "product_name", with: "Big Bag Of Potatoes"
    select(s2.name, :from => 'supplier_id')
    fill_in "available_on", with: (Date.today-3).strftime("%F %T")
    fill_in "price", with: "20"
    fill_in "on_hand", with: "18"

    click_button 'Update'
    page.find("span#update-status-message").should have_content "Update complete"

    visit '/admin/products/bulk_index'

    page.should have_field "product_name", with: "Big Bag Of Potatoes"
    page.should have_select "supplier_id", selected: s2.name
    page.should have_field "available_on", with: (Date.today-3).strftime("%F %T")
    page.should have_field "price", with: "20.0"
    page.should have_field "on_hand", with: "18"
  end
  
  scenario "updating a product with variants" do
    s1 = FactoryGirl.create(:supplier_enterprise)
    s2 = FactoryGirl.create(:supplier_enterprise)
    p = FactoryGirl.create(:product, supplier: s1, available_on: Date.today)
    v = FactoryGirl.create(:variant, product: p, price: 3.0, on_hand: 9)

    login_to_admin_section

    visit '/admin/products/bulk_index'

    page.should have_field "variant_price", with: "3.0"
    page.should have_field "variant_on_hand", with: "9"
    page.should have_selector "span[name='on_hand']", text: "9"

    fill_in "variant_price", with: "4.0"
    fill_in "variant_on_hand", with: "10"

    page.should have_selector "span[name='on_hand']", text: "10"

    click_button 'Update'
    page.find("span#update-status-message").should have_content "Update complete"

    visit '/admin/products/bulk_index'

    page.should have_field "variant_price", with: "4.0"
    page.should have_field "variant_on_hand", with: "10"
  end

  scenario "updating a product mutiple times without refresh" do
    p = FactoryGirl.create(:product, name: 'original name')
    login_to_admin_section

    visit '/admin/products/bulk_index'

    page.should have_field "product_name", with: "original name"

    fill_in "product_name", with: "new name 1"

    click_button 'Update'
    page.find("span#update-status-message").should have_content "Update complete"

    fill_in "product_name", with: "new name 2"

    click_button 'Update'
    page.find("span#update-status-message").should have_content "Update complete"

    fill_in "product_name", with: "original name"

    click_button 'Update'
    page.find("span#update-status-message").should have_content "Update complete"
  end

  describe "using action buttons" do
    describe "using delete buttons" do
      it "shows a delete button for products, which deletes the appropriate product when clicked" do
        p1 = FactoryGirl.create(:product)
        p2 = FactoryGirl.create(:product)
        p3 = FactoryGirl.create(:product)
        login_to_admin_section

        visit '/admin/products/bulk_index'

        page.should have_selector "a.delete-product", :count => 3

        first("a.delete-product").click

        page.should have_selector "a.delete-product", :count => 2
        #page.should have_selector "div.flash.notice", text: "Product has been deleted."

        visit '/admin/products/bulk_index'

        page.should have_selector "a.delete-product", :count => 2
      end     
    end
  end
end 