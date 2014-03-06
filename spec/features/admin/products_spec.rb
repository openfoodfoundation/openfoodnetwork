require "spec_helper"

feature %q{
    As an admin
    I want to set a supplier and distributor(s) for a product
} do
  include AuthenticationWorkflow
  include WebHelper

  background do
    @supplier = create(:supplier_enterprise, :name => 'New supplier')
    @distributors = (1..3).map { create(:distributor_enterprise) }
    @enterprise_fees = (0..2).map { |i| create(:enterprise_fee, enterprise: @distributors[i]) }
  end

  context "creating a product" do
    scenario "assigning a supplier, distributors and units to the product" do
      login_to_admin_section

      click_link 'Products'
      click_link 'New Product'

      fill_in 'product_name', with: 'A new product !!!'
      fill_in 'product_price', with: '19.99'
      select 'New supplier', from: 'product_supplier_id'
      select 'Weight', from: 'product_variant_unit'
      fill_in 'product_variant_unit_scale', with: 1000
      fill_in 'product_variant_unit_name', with: ''

      click_button 'Create'

      flash_message.should == 'Product "A new product !!!" has been successfully created!'
      product = Spree::Product.find_by_name('A new product !!!')
      product.supplier.should == @supplier
      product.group_buy.should be_false

      product.variant_unit.should == 'weight'
      product.variant_unit_scale.should == 1000
      product.variant_unit_name.should == ''
      product.option_types.first.name.should == 'unit_weight'

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


    scenario "creating a group buy product" do
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


      context "Additional fields" do
        #let(:product) { create(:simple_product, supplier: @supplier2) }

        it "should have a notes field" do
          product = create(:simple_product, supplier: @supplier2)
          click_link 'Products'
          within('#sub_nav') { click_link 'Products' }
          click_link product.name
          page.should have_content "Notes"
        end
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

      scenario "deleting product images", js: true do
        product = create(:simple_product, supplier: @supplier2)
        image = File.open(File.expand_path('../../../../app/assets/images/logo.jpg', __FILE__))
        Spree::Image.create({:viewable_id => product.master.id, :viewable_type => 'Spree::Variant', :alt => "position 1", :attachment => image, :position => 1})

        visit spree.admin_product_images_path(product)
        page.should have_selector "table[data-hook='images_table'] td img", visible: true
        product.reload.images.count.should == 1

        page.find('a.delete-resource').click
        wait_until { product.reload.images.count == 0 }

        page.should_not have_selector "table[data-hook='images_table'] td img", visible: true
      end
    end
  end
end
