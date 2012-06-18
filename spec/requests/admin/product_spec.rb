require "spec_helper"

feature %q{
    As a supplier
    I want set a supplier and distributor(s) for a product
} do
  include AuthenticationWorkflow
  include WebHelper

  background do
    @supplier = Spree::Supplier.make!(:name => 'New supplier')
    @distributors = (1..3).map { |i| Spree::Distributor.make!(:name => "Distributor #{i}") }
  end

  context "creating a product" do
    scenario "I should be able to assign a supplier to the product" do
      login_to_admin_section

      click_link 'Products'
      click_link 'New Product'

      fill_in 'product_name', :with => 'A new product !!!'
      fill_in 'product_price', :with => '19.99'
      select 'New supplier', :from => 'product_supplier_id'
      check @distributors[0].name
      check @distributors[2].name

      click_button 'Create'

      flash_message.should == 'Product "A new product !!!" has been successfully created!'
      product = Spree::Product.find_by_name('A new product !!!')
      product.supplier.should == @supplier
      product.distributors.should == [@distributors[0], @distributors[2]]
    end
  end

  context "Given I am cloning a Product"
end
