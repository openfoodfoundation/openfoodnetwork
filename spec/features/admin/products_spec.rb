require "spec_helper"

feature '
    As an admin
    I want to set a supplier and distributor(s) for a product
' do
  include WebHelper
  include AuthenticationHelper

  let!(:taxon) { create(:taxon) }
  let!(:stock_location) { create(:stock_location, backorderable_default: false) }
  let!(:shipping_category) { DefaultShippingCategory.find_or_create }

  background do
    @supplier = create(:supplier_enterprise, name: 'New supplier')
    @distributors = (1..3).map { create(:distributor_enterprise) }
    @enterprise_fees = (0..2).map { |i| create(:enterprise_fee, enterprise: @distributors[i]) }
  end

  context "as anonymous user" do
    it "is redirected to login page when attempting to access product listing" do
      expect { visit spree.admin_products_path }.not_to raise_error
    end
  end

  describe "creating a product" do
    let!(:tax_category) { create(:tax_category, name: 'Test Tax Category') }

    scenario "assigning important attributes", js: true do
      login_to_admin_section

      click_link 'Products'
      click_link 'New Product'

      expect(find_field('product_shipping_category_id').text).to eq(shipping_category.name)

      select 'New supplier', from: 'product_supplier_id'
      fill_in 'product_name', with: 'A new product !!!'
      select "Weight (kg)", from: 'product_variant_unit_with_scale'
      fill_in 'product_unit_value_with_description', with: 5
      select taxon.name, from: "product_primary_taxon_id"
      fill_in 'product_price', with: '19.99'
      fill_in 'product_on_hand', with: 5
      select 'Test Tax Category', from: 'product_tax_category_id'
      page.find("div[id^='taTextElement']").native.send_keys('A description...')

      click_button 'Create'

      expect(current_path).to eq spree.admin_products_path
      expect(flash_message).to eq('Product "A new product !!!" has been successfully created!')
      product = Spree::Product.find_by(name: 'A new product !!!')
      expect(product.supplier).to eq(@supplier)
      expect(product.variant_unit).to eq('weight')
      expect(product.variant_unit_scale).to eq(1000)
      expect(product.unit_value).to eq(5000)
      expect(product.unit_description).to eq("")
      expect(product.variant_unit_name).to eq("")
      expect(product.primary_taxon_id).to eq(taxon.id)
      expect(product.price.to_s).to eq('19.99')
      expect(product.on_hand).to eq(5)
      expect(product.tax_category_id).to eq(tax_category.id)
      expect(product.shipping_category).to eq(shipping_category)
      expect(product.description).to eq("<p>A description...</p>")
      expect(product.group_buy).to be_falsey
      expect(product.master.option_values.map(&:name)).to eq(['5kg'])
      expect(product.master.options_text).to eq("5kg")
    end

    scenario "creating an on-demand product", js: true do
      login_as_admin_and_visit spree.admin_products_path

      click_link 'New Product'

      fill_in 'product_name', with: 'Hot Cakes'
      select 'New supplier', from: 'product_supplier_id'
      select "Weight (kg)", from: 'product_variant_unit_with_scale'
      fill_in 'product_unit_value_with_description', with: 1
      select taxon.name, from: "product_primary_taxon_id"
      fill_in 'product_price', with: '1.99'
      fill_in 'product_on_hand', with: 0
      check 'product_on_demand'
      select 'Test Tax Category', from: 'product_tax_category_id'
      page.find("div[id^='taTextElement']").native.send_keys('In demand, and on_demand! The hottest cakes in town.')

      click_button 'Create'

      expect(current_path).to eq spree.admin_products_path
      product = Spree::Product.find_by(name: 'Hot Cakes')
      expect(product.variants.count).to eq(1)
      variant = product.variants.first
      expect(variant.on_demand).to be true
    end
  end

  context "as an enterprise user" do
    let!(:tax_category) { create(:tax_category) }

    before do
      @new_user = create(:user)
      @supplier2 = create(:supplier_enterprise, name: 'Another Supplier')
      @supplier_permitted = create(:supplier_enterprise, name: 'Permitted Supplier')
      @new_user.enterprise_roles.build(enterprise: @supplier2).save
      @new_user.enterprise_roles.build(enterprise: @distributors[0]).save
      create(:enterprise_relationship, parent: @supplier_permitted, child: @supplier2,
                                       permissions_list: [:manage_products])

      login_as @new_user
    end

    context "products do not require a tax category" do
      scenario "creating a new product", js: true do
        with_products_require_tax_category(false) do
          visit spree.admin_products_path
          click_link 'New Product'

          fill_in 'product_name', with: 'A new product !!!'
          fill_in 'product_price', with: '19.99'

          expect(page).to have_selector('#product_supplier_id')
          select 'Another Supplier', from: 'product_supplier_id'
          select 'Weight (g)', from: 'product_variant_unit_with_scale'
          fill_in 'product_unit_value_with_description', with: '500'
          select taxon.name, from: "product_primary_taxon_id"
          select 'None', from: "product_tax_category_id"

          # Should only have suppliers listed which the user can manage
          expect(page).to have_select 'product_supplier_id', with_options: [@supplier2.name, @supplier_permitted.name]
          expect(page).not_to have_select 'product_supplier_id', with_options: [@supplier.name]

          click_button 'Create'

          expect(flash_message).to eq('Product "A new product !!!" has been successfully created!')
          product = Spree::Product.find_by(name: 'A new product !!!')
          expect(product.supplier).to eq(@supplier2)
          expect(product.tax_category).to be_nil
        end
      end
    end

    scenario "editing a product" do
      product = create(:simple_product, name: 'a product', supplier: @supplier2)

      visit spree.edit_admin_product_path product

      select 'Permitted Supplier', from: 'product_supplier_id'
      select tax_category.name, from: 'product_tax_category_id'
      click_button 'Update'
      expect(flash_message).to eq('Product "a product" has been successfully updated!')
      product.reload
      expect(product.supplier).to eq(@supplier_permitted)
      expect(product.tax_category).to eq(tax_category)
    end

    scenario "editing product group buy options" do
      product = product = create(:simple_product, supplier: @supplier2)

      visit spree.edit_admin_product_path product
      within('#sidebar') { click_link 'Group Buy Options' }
      choose('product_group_buy_1')
      fill_in 'Bulk unit size', with: '10'

      click_button 'Update'

      expect(flash_message).to eq("Product \"#{product.name}\" has been successfully updated!")
      product.reload
      expect(product.group_buy).to be true
      expect(product.group_buy_unit_size).to eq(10.0)
    end

    scenario "editing product Search" do
      product = product = create(:simple_product, supplier: @supplier2)
      visit spree.edit_admin_product_path product
      within('#sidebar') { click_link 'Search' }
      fill_in 'Product Search Keywords', with: 'Product Search Keywords'
      fill_in 'Notes', with: 'Just testing Notes'
      click_button 'Update'
      expect(flash_message).to eq("Product \"#{product.name}\" has been successfully updated!")
      product.reload
      expect(product.notes).to eq('Just testing Notes')
      expect(product.meta_keywords).to eq('Product Search Keywords')
    end

    scenario "deleting product properties", js: true do
      # Given a product with a property
      p = create(:simple_product, supplier: @supplier2)
      p.set_property('fooprop', 'fooval')

      # When I navigate to the product properties page
      visit spree.admin_product_product_properties_path(p)
      expect(page).to have_select2 'product_product_properties_attributes_0_property_name', selected: 'fooprop'
      expect(page).to have_field 'product_product_properties_attributes_0_value', with: 'fooval'

      # And I delete the property
      accept_alert do
        page.all('a.delete-resource').first.click
      end
      click_button 'Update'

      # Then the property should have been deleted
      expect(page).not_to have_field 'product_product_properties_attributes_0_property_name', with: 'fooprop'
      expect(page).not_to have_field 'product_product_properties_attributes_0_value', with: 'fooval'
      expect(p.reload.property('fooprop')).to be_nil
    end

    scenario "loading new image page", js: true do
      product = create(:simple_product, supplier: @supplier2)

      visit spree.admin_product_images_path(product)
      expect(page).to have_selector ".no-objects-found"

      page.find('a#new_image_link').click
      expect(page).to have_selector "#image_attachment"
    end

    scenario "deleting product images", js: true do
      product = create(:simple_product, supplier: @supplier2)
      image = File.open(File.expand_path('../../../app/assets/images/logo-white.png', __dir__))
      Spree::Image.create(viewable_id: product.master.id, viewable_type: 'Spree::Variant', alt: "position 1", attachment: image, position: 1)

      visit spree.admin_product_images_path(product)
      expect(page).to have_selector "table.index td img"
      expect(product.reload.images.count).to eq 1

      accept_alert do
        page.find('a.delete-resource').click
      end

      expect(page).to_not have_selector "table.index td img"
      expect(product.reload.images.count).to eq 0
    end
  end
end
