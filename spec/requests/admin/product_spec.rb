require "spec_helper"

feature %q{
    As a supplier
    I want set a supplier for a product
} do
  include AuthenticationWorkflow
  include WebHelper

  background do
    @supplier = Spree::Supplier.make!(:name => 'New supplier')
  end

  context "Given I am creating a Product" do
    scenario "I should be able to assign a supplier to the Product" do
      login_to_admin_section

      click_link 'Products'
      click_link 'New Product'

      fill_in 'product_name', :with => 'A new product !!!'
      fill_in 'product_price', :with => '19.99'
      select('New supplier', :from => 'product_supplier_id')

      click_button 'Create'

      flash_message.should == 'Product "A new product !!!" has been successfully created!'
      Spree::Product.find_by_name('A new product !!!').supplier.should == @supplier
    end
  end

  context "Given I am cloning a Product"
end
