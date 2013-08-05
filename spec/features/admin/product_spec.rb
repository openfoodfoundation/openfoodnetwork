require "spec_helper"

feature %q{
    As a supplier
    I want set a supplier and distributor(s) for a product
} do
  include AuthenticationWorkflow
  include WebHelper

  background do
    @supplier = create(:supplier_enterprise, :name => 'New supplier')
    @distributors = (1..3).map { create(:distributor_enterprise) }
    @shipping_method = create(:shipping_method, :name => 'My shipping method')
  end

  context "creating a product" do
    scenario "assigning a supplier and distributors to the product" do
      login_to_admin_section

      click_link 'Products'
      click_link 'New Product'

      fill_in 'product_name', :with => 'A new product !!!'
      fill_in 'product_price', :with => '19.99'
      select 'New supplier', :from => 'product_supplier_id'

      check @distributors[0].name
      select 'My shipping method', :from => 'product_product_distributions_attributes_0_shipping_method_id'
      check @distributors[2].name
      select 'My shipping method', :from => 'product_product_distributions_attributes_2_shipping_method_id'

      click_button 'Create'

      flash_message.should == 'Product "A new product !!!" has been successfully created!'
      product = Spree::Product.find_by_name('A new product !!!')
      product.supplier.should == @supplier
      product.distributors.should == [@distributors[0], @distributors[2]]
      product.product_distributions.map { |pd| pd.shipping_method }.should == [@shipping_method, @shipping_method]
      product.group_buy.should be_false
    end

    scenario "making a group buy product" do
      login_to_admin_section

      click_link 'Products'
      click_link 'New Product'

      fill_in 'product_name', :with => 'A new product !!!'
      fill_in 'product_price', :with => '19.99'
      select 'New supplier', :from => 'product_supplier_id'
      choose 'product_group_buy_1'
      fill_in 'Group buy unit size', :with => '10'

      click_button 'Create'

      flash_message.should == 'Product "A new product !!!" has been successfully created!'
      product = Spree::Product.find_by_name('A new product !!!')
      product.group_buy.should be_true
      product.group_buy_unit_size.should == 10.0
    end


    describe 'As an enterprise user' do

      before(:each) do
        @new_user = create_enterprise_user
        @supplier2 = create(:supplier_enterprise, name: 'Another Supplier')
        @new_user.enterprise_roles.build(enterprise: @supplier2).save
        @new_user.enterprise_roles.build(enterprise: @distributors[0]).save

        login_to_admin_as @new_user
      end

      scenario "create new product" do
        click_link 'Products'
        click_link 'New Product'

        fill_in 'product_name', :with => 'A new product !!!'
        fill_in 'product_price', :with => '19.99'

        page.should have_selector('#product_supplier_id')
        select 'Another Supplier', :from => 'product_supplier_id'

        # Should only have suppliers listed which the user can manage
        within "#product_supplier_id" do
          page.should_not have_content @supplier.name
        end

        check @distributors[0].name
        select 'My shipping method', :from => 'product_product_distributions_attributes_0_shipping_method_id'

        # Should only have distributors listed which the user can manage
        within "#product_product_distributions_field" do
          page.should_not have_content @distributors[1].name
          page.should_not have_content @distributors[2].name
        end

        click_button 'Create'

        flash_message.should == 'Product "A new product !!!" has been successfully created!'
        product = Spree::Product.find_by_name('A new product !!!')
        product.supplier.should == @supplier2
        product.distributors.should == [@distributors[0]]
      end

      describe 'with existing product' do
        before(:each) do
          @product = create(:product, supplier: @supplier2)
        end

        scenario "can edit" do
          click_link 'Products'

          click_link @product.name
          page.should_not have_selector('#product_supplier_id')

          click_link "Images"
          page.should_not have_content 'Authorization Failure'

          click_link "Variants"
          page.should_not have_content 'Authorization Failure'

          click_link "Product Properties"
          page.should_not have_content 'Authorization Failure'
        end
      end
    end
  end
end
