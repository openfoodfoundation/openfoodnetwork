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

      visit '/admin/products/bulk_edit'

      page.should have_field "product_name", with: p1.name
      page.should have_field "product_name", with: p2.name
    end

    it "displays a select box for suppliers, with the appropriate supplier selected" do
      s1 = FactoryGirl.create(:supplier_enterprise)
      s2 = FactoryGirl.create(:supplier_enterprise)
      s3 = FactoryGirl.create(:supplier_enterprise)
      p1 = FactoryGirl.create(:product, supplier: s2)
      p2 = FactoryGirl.create(:product, supplier: s3)

      visit '/admin/products/bulk_edit'

      page.should have_select "supplier", with_options: [s1.name,s2.name,s3.name], selected: s2.name
      page.should have_select "supplier", with_options: [s1.name,s2.name,s3.name], selected: s3.name
    end

    it "displays a date input for available_on for each product, formatted to yyyy-mm-dd hh:mm:ss" do
      p1 = FactoryGirl.create(:product, available_on: Date.today)
      p2 = FactoryGirl.create(:product, available_on: Date.today-1)

      visit '/admin/products/bulk_edit'

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

      visit '/admin/products/bulk_edit'

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

      visit '/admin/products/bulk_edit'

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

      visit '/admin/products/bulk_edit'

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

      visit '/admin/products/bulk_edit'
      page.should have_selector "a.view-variants"
      first("a.view-variants").click

      page.should have_field "product_name", with: v1.product.name
      page.should have_field "product_name", with: v2.product.name
      page.should have_selector "td", text: v1.options_text
      page.should have_selector "td", text: v2.options_text
    end

    it "displays an on_hand input (for each variant) for each product" do
      p1 = FactoryGirl.create(:product)
      v1 = FactoryGirl.create(:variant, product: p1, is_master: false, on_hand: 15)
      v2 = FactoryGirl.create(:variant, product: p1, is_master: false, on_hand: 6)

      visit '/admin/products/bulk_edit'

      page.should have_selector "span[name='on_hand']", text: "21"
      page.should have_field "variant_on_hand", with: "15"
      page.should have_field "variant_on_hand", with: "6"
    end
    
   
    it "displays a price input (for each variant) for each product" do
      p1 = FactoryGirl.create(:product, price: 2.0)
      v1 = FactoryGirl.create(:variant, product: p1, is_master: false, price: 12.75)
      v2 = FactoryGirl.create(:variant, product: p1, is_master: false, price: 2.50)

      visit '/admin/products/bulk_edit'

      page.should have_field "price", with: "2.0"
      page.should have_field "variant_price", with: "12.75"
      page.should have_field "variant_price", with: "2.5"
    end
  end

  scenario "create a new product" do
    s = FactoryGirl.create(:supplier_enterprise)
    d = FactoryGirl.create(:distributor_enterprise)

    login_to_admin_section

    visit '/admin/products/bulk_edit'

    click_link 'New Product'

    page.should have_content 'NEW PRODUCT'

    fill_in 'product_name', :with => 'Big Bag Of Apples'
    select(s.name, :from => 'product_supplier_id')
    choose('product_group_buy_0')
    fill_in 'product_price', :with => '10.00'
    fill_in 'product_available_on', :with => Date.today.strftime("%Y/%m/%d")
    check('product_product_distributions_attributes_0__destroy')
    click_button 'Create'

    URI.parse(current_url).path.should == '/admin/products/bulk_edit'
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

    visit '/admin/products/bulk_edit'

    page.should have_field "product_name", with: p.name
    page.should have_select "supplier", selected: s1.name
    page.should have_field "available_on", with: p.available_on.strftime("%F %T")
    page.should have_field "price", with: "10.0"
    page.should have_field "on_hand", with: "6"

    fill_in "product_name", with: "Big Bag Of Potatoes"
    select(s2.name, :from => 'supplier')
    fill_in "available_on", with: (Date.today-3).strftime("%F %T")
    fill_in "price", with: "20"
    fill_in "on_hand", with: "18"

    click_button 'Update'
    page.find("span#update-status-message").should have_content "Update complete"

    visit '/admin/products/bulk_edit'

    page.should have_field "product_name", with: "Big Bag Of Potatoes"
    page.should have_select "supplier", selected: s2.name
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

    visit '/admin/products/bulk_edit'
    page.should have_selector "a.view-variants"
    first("a.view-variants").click

    page.should have_field "variant_price", with: "3.0"
    page.should have_field "variant_on_hand", with: "9"
    page.should have_selector "span[name='on_hand']", text: "9"

    fill_in "variant_price", with: "4.0"
    fill_in "variant_on_hand", with: "10"

    page.should have_selector "span[name='on_hand']", text: "10"

    click_button 'Update'
    page.find("span#update-status-message").should have_content "Update complete"

    visit '/admin/products/bulk_edit'
    page.should have_selector "a.view-variants"
    first("a.view-variants").click

    page.should have_field "variant_price", with: "4.0"
    page.should have_field "variant_on_hand", with: "10"
  end

  scenario "updating delegated attributes of variants in isolation" do
    p = FactoryGirl.create(:product)
    v = FactoryGirl.create(:variant, product: p, price: 3.0)

    login_to_admin_section

    visit '/admin/products/bulk_edit'
    page.should have_selector "a.view-variants"
    first("a.view-variants").click

    page.should have_field "variant_price", with: "3.0"

    fill_in "variant_price", with: "10.0"

    click_button 'Update'
    page.find("span#update-status-message").should have_content "Update complete"

    visit '/admin/products/bulk_edit'
    page.should have_selector "a.view-variants"
    first("a.view-variants").click

    page.should have_field "variant_price", with: "10.0"
  end

  scenario "updating a product mutiple times without refresh" do
    p = FactoryGirl.create(:product, name: 'original name')
    login_to_admin_section

    visit '/admin/products/bulk_edit'

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

        visit '/admin/products/bulk_edit'

        page.should have_selector "a.delete-product", :count => 3

        first("a.delete-product").click

        sleep(0.5) if page.has_selector? "a.delete-product", :count => 3 # Wait for product to be removed from page
        page.should have_selector "a.delete-product", :count => 2

        visit '/admin/products/bulk_edit'

        page.should have_selector "a.delete-product", :count => 2
      end

      it "shows a delete button for variants, which deletes the appropriate variant when clicked" do
        v1 = FactoryGirl.create(:variant)
        v2 = FactoryGirl.create(:variant)
        v3 = FactoryGirl.create(:variant)
        login_to_admin_section

        visit '/admin/products/bulk_edit'
        page.should have_selector "a.view-variants"
        all("a.view-variants").each{ |e| e.click }

        page.should have_selector "a.delete-variant", :count => 3

        first("a.delete-variant").click
        
        sleep(0.5) if page.has_selector? "a.delete-variant", :count => 3 # Wait for variant to be removed from page
        page.should have_selector "a.delete-variant", :count => 2

        visit '/admin/products/bulk_edit'
        page.should have_selector "a.view-variants"
        all("a.view-variants").select{ |e| e.visible? }.each{ |e| e.click }

        page.should have_selector "a.delete-variant", :count => 2
      end
    end

    describe "using edit buttons" do
      it "shows an edit button for products, which takes the user to the standard edit page for that product" do
        p1 = FactoryGirl.create(:product)
        p2 = FactoryGirl.create(:product)
        p3 = FactoryGirl.create(:product)
        login_to_admin_section

        visit '/admin/products/bulk_edit'

        page.should have_selector "a.edit-product", :count => 3

        first("a.edit-product").click

        URI.parse(current_url).path.should == "/admin/products/#{p1.permalink}/edit"
      end

      it "shows an edit button for variants, which takes the user to the standard edit page for that variant" do
        v1 = FactoryGirl.create(:variant)
        v2 = FactoryGirl.create(:variant)
        v3 = FactoryGirl.create(:variant)
        login_to_admin_section

        visit '/admin/products/bulk_edit'
        page.should have_selector "a.view-variants"
        first("a.view-variants").click

        page.should have_selector "a.edit-variant", :count => 3

        first("a.edit-variant").click

        URI.parse(current_url).path.should == "/admin/products/#{v1.product.permalink}/variants/#{v1.id}/edit"
      end
    end

    describe "using clone buttons" do
      it "shows a clone button for products, which duplicates the product and adds it to the page when clicked" do
        p1 = FactoryGirl.create(:product, :name => "P1")
        p2 = FactoryGirl.create(:product, :name => "P2")
        p3 = FactoryGirl.create(:product, :name => "P3")
        login_to_admin_section

        visit '/admin/products/bulk_edit'

        page.should have_selector "a.clone-product", :count => 3

        first("a.clone-product").click

        page.should have_selector "a.clone-product", :count => 4
        page.should have_field "product_name", with: "COPY OF #{p1.name}"
        page.should have_select "supplier", selected: "#{p1.supplier.name}"

        visit '/admin/products/bulk_edit'

        page.should have_selector "a.clone-product", :count => 4
        page.should have_field "product_name", with: "COPY OF #{p1.name}"
        page.should have_select "supplier", selected: "#{p1.supplier.name}"
      end
    end
  end

  describe "using the page" do
    describe "using column display toggle" do
      it "shows a column display toggle button, which shows a list of columns when clicked" do
        login_to_admin_section

        visit '/admin/products/bulk_edit'

        page.should have_selector "th", :text => "NAME"
        page.should have_selector "th", :text => "SUPPLIER"
        page.should have_selector "th", :text => "PRICE"
        page.should have_selector "th", :text => "ON HAND"
        page.should have_selector "th", :text => "AV. ON"

        page.should have_button "Toggle Columns"

        click_button "Toggle Columns"

        page.should have_selector "div ul.column-list li.column-list-item", text: "Supplier"
        all("div ul.column-list li.column-list-item").select{ |e| e.text == "Supplier" }.first.click

        page.should_not have_selector "th", :text => "SUPPLIER"
        page.should have_selector "th", :text => "NAME"
        page.should have_selector "th", :text => "PRICE"
        page.should have_selector "th", :text => "ON HAND"
        page.should have_selector "th", :text => "AV. ON"
      end
    end
  end

  context "as an enterprise manager" do
    let(:s1) { create(:supplier_enterprise, name: 'First Supplier') }
    let(:s2) { create(:supplier_enterprise, name: 'Another Supplier') }
    let(:s3) { create(:supplier_enterprise, name: 'Yet Another Supplier') }
    let(:d1) { create(:distributor_enterprise, name: 'First Distributor') }
    let(:d2) { create(:distributor_enterprise, name: 'Another Distributor') }
    let!(:product_supplied) { create(:product, supplier: s1, price: 10.0, on_hand: 6) }
    let!(:product_not_supplied) { create(:product, supplier: s3) }

    before(:each) do
      @enterprise_user = create_enterprise_user
      @enterprise_user.enterprise_roles.build(enterprise: s1).save
      @enterprise_user.enterprise_roles.build(enterprise: s2).save
      @enterprise_user.enterprise_roles.build(enterprise: d1).save

      login_to_admin_as @enterprise_user
    end

    it "shows only products that I supply" do
      visit '/admin/products/bulk_edit'

      page.should have_field 'product_name', with: product_supplied.name
      page.should_not have_field 'product_name', with: product_not_supplied.name
    end

    it "shows only suppliers that I manage" do
      visit '/admin/products/bulk_edit'

      page.should have_select 'supplier', with_options: [s1.name, s2.name], selected: s1.name
      page.should_not have_select 'supplier', with_options: [s3.name]
    end

    it "allows me to update a product" do
      p = product_supplied

      visit '/admin/products/bulk_edit'

      page.should have_field "product_name", with: p.name
      page.should have_select "supplier", selected: s1.name
      page.should have_field "available_on", with: p.available_on.strftime("%F %T")
      page.should have_field "price", with: "10.0"
      page.should have_field "on_hand", with: "6"

      fill_in "product_name", with: "Big Bag Of Potatoes"
      select s2.name, from: 'supplier'
      fill_in "available_on", with: (Date.today-3).strftime("%F %T")
      fill_in "price", with: "20"
      fill_in "on_hand", with: "18"

      click_button 'Update'
      page.find("span#update-status-message").should have_content "Update complete"

      visit '/admin/products/bulk_edit'

      page.should have_field "product_name", with: "Big Bag Of Potatoes"
      page.should have_select "supplier", selected: s2.name
      page.should have_field "available_on", with: (Date.today-3).strftime("%F %T")
      page.should have_field "price", with: "20.0"
      page.should have_field "on_hand", with: "18"
    end
  end
end
