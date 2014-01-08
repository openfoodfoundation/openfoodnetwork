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
    @enterprise_fees = (0..2).map { |i| create(:enterprise_fee, enterprise: @distributors[i]) }
  end

  context "creating a product" do
    scenario "assigning a supplier and distributors to the product" do
      login_to_admin_section

      click_link 'Products'
      click_link 'New Product'

      fill_in 'product_name', :with => 'A new product !!!'
      fill_in 'product_price', :with => '19.99'
      select 'New supplier', :from => 'product_supplier_id'

      click_button 'Create'

      flash_message.should == 'Product "A new product !!!" has been successfully created!'
      product = Spree::Product.find_by_name('A new product !!!')
      product.supplier.should == @supplier
      product.group_buy.should be_false

      # Distributors
      within('#sidebar') { click_link 'Product Distributions' }

      check @distributors[0].name
      select @enterprise_fees[0].name, :from => 'product_product_distributions_attributes_0_enterprise_fee_id'
      check @distributors[2].name
      select @enterprise_fees[2].name, :from => 'product_product_distributions_attributes_2_enterprise_fee_id'

      click_button 'Update'
      
      product.reload
      product.distributors.should == [@distributors[0], @distributors[2]]
      product.product_distributions.map { |pd| pd.enterprise_fee }.should == [@enterprise_fees[0], @enterprise_fees[2]]
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


    context "as an enterprise user" do

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

        click_button 'Create'

        flash_message.should == 'Product "A new product !!!" has been successfully created!'
        product = Spree::Product.find_by_name('A new product !!!')
        product.supplier.should == @supplier2
      end

      scenario "editing product distributions" do
        product = create(:simple_product, supplier: @supplier2)

        click_link 'Products'
        within('#sub_nav') { click_link 'Products' }
        click_link product.name
        within('#sidebar') { click_link 'Product Distributions' }

        check @distributors[0].name
        select @enterprise_fees[0].name, :from => 'product_product_distributions_attributes_0_enterprise_fee_id'

        # Should only have distributors listed which the user can manage
        within "#product_product_distributions_field" do
          page.should_not have_content @distributors[1].name
          page.should_not have_content @distributors[2].name
        end

        click_button 'Update'
        flash_message.should == "Product \"#{product.name}\" has been successfully updated!"

        product.distributors.should == [@distributors[0]]
      end
    end
  end
end
