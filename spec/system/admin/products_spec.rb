# frozen_string_literal: true

require "system_helper"

describe '
    As an admin
    I want to set a supplier and distributor(s) for a product
' do
  include WebHelper
  include AuthenticationHelper
  include FileHelper

  let!(:taxon) { create(:taxon) }
  let!(:stock_location) { create(:stock_location, backorderable_default: false) }
  let!(:shipping_category) { DefaultShippingCategory.find_or_create }

  before do
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

    it "display all attributes when submitting with error: no name" do
      login_to_admin_section

      click_link 'Products'
      click_link 'New Product'

      select @supplier.name, from: 'product_supplier_id'
      select "Weight (kg)", from: 'product_variant_unit_with_scale'
      fill_in 'product_unit_value', with: "5.00 g"
      assert_selector(:field, placeholder: "5kg g")
      fill_in 'product_display_as', with: "Big Box of Chocolates"
      select taxon.name, from: "product_primary_taxon_id"
      fill_in 'product_price', with: '19.99'
      fill_in 'product_on_hand', with: 5
      check 'product_on_demand'
      select 'Test Tax Category', from: 'product_tax_category_id'
      page.find("div[id^='taTextElement']").native.send_keys('A description...')

      click_button 'Create'

      expect(page).to have_content "Name can't be blank"
      expect(page).to have_field 'product_supplier_id', with: @supplier.id
      expect(page).to have_field 'product_unit_value', with: "5.00 g"
      expect(page).to have_field 'product_display_as', with: "Big Box of Chocolates"
      expect(page).to have_field 'product_primary_taxon_id', with: taxon.id
      expect(page).to have_field 'product_price', with: '19.99'
      expect(page).to have_field 'product_on_hand', with: 5
      expect(page).to have_field 'product_on_demand', checked: true
      expect(page).to have_field 'product_tax_category_id', with: tax_category.id
      expect(page.find("div[id^='taTextElement']")).to have_content 'A description...'
      expect(page.find("#product_variant_unit_field")).to have_content 'Weight (kg)'

      expect(page).to have_content "Name can't be blank"
    end

    it "preserves 'Items' 'Unit Size' selection when submitting with error" do
      login_to_admin_section

      click_link 'Products'
      click_link 'New Product'

      select "Items", from: 'product_variant_unit_with_scale'

      click_button 'Create'

      expect(page.find("#product_variant_unit_field")).to have_content 'Items'
    end

    it "assigning important attributes" do
      login_to_admin_section

      click_link 'Products'
      click_link 'New Product'

      expect(find_field('product_shipping_category_id').text).to eq(shipping_category.name)

      select 'New supplier', from: 'product_supplier_id'
      fill_in 'product_name', with: 'A new product !!!'
      select "Weight (kg)", from: 'product_variant_unit_with_scale'
      fill_in 'product_unit_value', with: 5
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

    it "creating an on-demand product" do
      login_as_admin_and_visit spree.admin_products_path

      click_link 'New Product'

      fill_in 'product_name', with: 'Hot Cakes'
      select 'New supplier', from: 'product_supplier_id'
      select "Weight (kg)", from: 'product_variant_unit_with_scale'
      fill_in 'product_unit_value', with: 1
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

    it "creating product with empty unit value" do
      login_as_admin_and_visit spree.admin_products_path

      click_link 'New Product'

      fill_in 'product_name', with: 'Hot Cakes'
      select 'New supplier', from: 'product_supplier_id'
      select "Weight (kg)", from: 'product_variant_unit_with_scale'
      fill_in "product_unit_value", with: ""
      select taxon.name, from: "product_primary_taxon_id"
      fill_in 'product_price', with: '1.99'
      fill_in 'product_on_hand', with: 0
      check 'product_on_demand'
      select 'Test Tax Category', from: 'product_tax_category_id'
      find("div[id^='taTextElement']").native.send_keys('In demand, and on_demand! The hottest cakes in town.')

      click_button 'Create'

      expect(current_path).to eq spree.admin_products_path
      expect(page).to have_content "Unit value can't be blank"
    end
  end

  describe "deleting" do
    let!(:product1) { create(:simple_product, name: 'a product to keep', supplier: @supplier) }

    context 'a simple product' do
      let!(:product2) { create(:simple_product, name: 'a product to delete', supplier: @supplier) }

      before do
        login_as_admin_and_visit spree.admin_products_path

        within "#p_#{product2.id}" do
          accept_alert { page.find("[data-powertip=Remove]").click }
        end
        visit current_path
      end

      it 'removes it from the product list' do
        expect(page).not_to have_selector "#p_#{product2.id}"
        expect(page).to have_selector "#p_#{product1.id}"
      end
    end

    context 'a shipped product' do
      let!(:order) { create(:shipped_order, line_items_count: 1) }
      let!(:line_item) { order.reload.line_items.first }

      context "a deleted line item from a shipped order" do
        before do
          login_as_admin_and_visit spree.admin_products_path

          within "#p_#{order.variants.first.product_id}" do
            accept_alert { page.find("[data-powertip=Remove]").click }
          end
        end

        it 'removes it from the product list' do
          visit spree.admin_products_path

          expect(page).to have_selector "#p_#{product1.id}"
          expect(page).not_to have_selector "#p_#{order.variants.first.product_id}"
        end

        it 'keeps the line item on the order (admin)' do
          visit spree.edit_admin_order_path(order)

          expect(page).to have_content(line_item.product.name.to_s)
        end
      end
    end
  end

  describe 'cloning' do
    let!(:product1) {
      create(:simple_product, name: 'a weight product', supplier: @supplier, variant_unit: "weight")
    }

    context 'products' do
      before do
        login_as_admin_and_visit spree.admin_products_path
      end

      it 'creates a copy of the product' do
        within "#p_#{product1.id}" do
          page.find("[data-powertip=Clone]").click
        end
        visit current_path
        within "#p_#{product1.id + 1}" do
          expect(page).to have_input "product_name", with: 'COPY OF a weight product'
        end
      end
    end
  end

  context "as an enterprise user" do
    let!(:tax_category) { create(:tax_category) }
    let(:filter) { { producerFilter: 2 } }

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
      it "creating a new product" do
        with_products_require_tax_category(false) do
          visit spree.admin_products_path
          click_link 'New Product'

          fill_in 'product_name', with: 'A new product !!!'
          fill_in 'product_price', with: '19.99'

          expect(page).to have_selector('#product_supplier_id')
          select 'Another Supplier', from: 'product_supplier_id'
          select 'Weight (g)', from: 'product_variant_unit_with_scale'
          fill_in 'product_unit_value', with: '500'
          select taxon.name, from: "product_primary_taxon_id"
          select 'None', from: "product_tax_category_id"

          # Should only have suppliers listed which the user can manage
          expect(page).to have_select 'product_supplier_id',
                                      with_options: [@supplier2.name, @supplier_permitted.name]
          expect(page).not_to have_select 'product_supplier_id', with_options: [@supplier.name]

          click_button 'Create'

          expect(flash_message).to eq('Product "A new product !!!" has been successfully created!')
          product = Spree::Product.find_by(name: 'A new product !!!')
          expect(product.supplier).to eq(@supplier2)
          expect(product.tax_category).to be_nil
        end
      end
    end

    it "editing a product" do
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

    it "editing a product comming from the bulk product update page with filter" do
      product = create(:simple_product, name: 'a product', supplier: @supplier2)

      visit spree.edit_admin_product_path(product, filter)

      click_button 'Update'
      expect(flash_message).to eq('Product "a product" has been successfully updated!')

      # Check the url still includes the filters
      uri = URI.parse(current_url)
      expect("#{uri.path}?#{uri.query}").to eq spree.edit_admin_product_path(product, filter)

      # Link back to the bulk product update page should include the filters
      expected_admin_product_url = Regexp.new(Regexp.escape("#{spree.admin_products_path}#?#{filter.to_query}"))
      expect(page).to have_link('Back to products list',
                                href: expected_admin_product_url)
      expect(page).to have_link('Cancel', href: expected_admin_product_url)

      expected_product_url = Regexp.new(Regexp.escape(spree.edit_admin_product_path(
                                                        product.permalink, filter
                                                      )))
      expect(page).to have_link('Product Details',
                                href: expected_product_url)

      expected_product_image_url = Regexp.new(Regexp.escape(spree.admin_product_images_path(
                                                              product.permalink, filter
                                                            )))
      expect(page).to have_link('Images',
                                href: expected_product_image_url)

      expected_product_variant_url = Regexp.new(Regexp.escape(spree.admin_product_variants_path(
                                                                product.permalink, filter
                                                              )))
      expect(page).to have_link('Variants',
                                href: expected_product_variant_url)

      expected_product_properties_url = Regexp.new(Regexp.escape(spree.admin_product_product_properties_path(
                                                                   product.permalink, filter
                                                                 )))
      expect(page).to have_link('Product Properties',
                                href: expected_product_properties_url)

      expected_product_group_buy_option_url = Regexp.new(Regexp.escape(spree.group_buy_options_admin_product_path(
                                                                         product.permalink, filter
                                                                       )))
      expect(page).to have_link('Group Buy Options',
                                href: expected_product_group_buy_option_url)

      expected_product_seo_url = Regexp.new(Regexp.escape(spree.seo_admin_product_path(
                                                            product.permalink, filter
                                                          )))
      expect(page).to have_link('Search', href: expected_product_seo_url)
    end

    it "editing product group buy options" do
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

    it "loading editing product group buy options with url filters" do
      product = product = create(:simple_product, supplier: @supplier2)

      visit spree.group_buy_options_admin_product_path(product, filter)

      expected_cancel_link = Regexp.new(Regexp.escape(spree.edit_admin_product_path(product,
                                                                                    filter)))
      expect(page).to have_link('Cancel', href: expected_cancel_link)
    end

    it "editing product group buy options with url filter" do
      product = product = create(:simple_product, supplier: @supplier2)

      visit spree.group_buy_options_admin_product_path(product, filter)
      choose('product_group_buy_1')
      fill_in 'Bulk unit size', with: '10'

      click_button 'Update'

      uri = URI.parse(current_url)
      expect("#{uri.path}?#{uri.query}").to eq spree.edit_admin_product_path(product, filter)
    end

    it "editing product Search" do
      product = create(:simple_product, supplier: @supplier2)
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

    it "loading editing product Search with url filters" do
      product = create(:simple_product, supplier: @supplier2)

      visit spree.seo_admin_product_path(product, filter)

      expected_cancel_link = Regexp.new(Regexp.escape(spree.edit_admin_product_path(product,
                                                                                    filter)))
      expect(page).to have_link('Cancel', href: expected_cancel_link)
    end

    it "editing product Search with url filter" do
      product = create(:simple_product, supplier: @supplier2)

      visit spree.seo_admin_product_path(product, filter)

      fill_in 'Product Search Keywords', with: 'Product Search Keywords'
      fill_in 'Notes', with: 'Just testing Notes'

      click_button 'Update'

      uri = URI.parse(current_url)
      expect("#{uri.path}?#{uri.query}").to eq spree.edit_admin_product_path(product, filter)
    end

    it "loading product properties page including url filters" do
      product = create(:simple_product, supplier: @supplier2)
      visit spree.admin_product_product_properties_path(product, filter)

      uri = URI.parse(current_url)
      # we stay on the same url as the new image content is loaded via an ajax call
      expect("#{uri.path}?#{uri.query}").to eq spree.admin_product_product_properties_path(product,
                                                                                           filter)

      expected_cancel_link = Regexp.new(Regexp.escape(spree.admin_product_product_properties_path(
                                                        product, filter
                                                      )))
      expect(page).to have_link('Cancel', href: expected_cancel_link)
    end

    it "deleting product properties" do
      # Given a product with a property
      product = create(:simple_product, supplier: @supplier2)
      product.set_property('fooprop', 'fooval')

      # When I navigate to the product properties page
      visit spree.admin_product_product_properties_path(product)
      expect(page).to have_select2 'product_product_properties_attributes_0_property_name',
                                   selected: 'fooprop'
      expect(page).to have_field 'product_product_properties_attributes_0_value', with: 'fooval'

      # And I delete the property
      accept_alert do
        page.all('a.delete-resource').first.click
      end
      click_button 'Update'

      # Then the property should have been deleted
      expect(page).not_to have_field 'product_product_properties_attributes_0_property_name',
                                     with: 'fooprop'
      expect(page).not_to have_field 'product_product_properties_attributes_0_value', with: 'fooval'
      expect(product.reload.property('fooprop')).to be_nil
    end

    it "deleting product properties including url filters" do
      # Given a product with a property
      product = create(:simple_product, supplier: @supplier2)
      product.set_property('fooprop', 'fooval')

      # When I navigate to the product properties page
      visit spree.admin_product_product_properties_path(product, filter)

      # And I delete the property
      accept_alert do
        page.all('a.delete-resource').first.click
      end

      uri = URI.parse(current_url)
      expect("#{uri.path}?#{uri.query}").to eq spree.admin_product_product_properties_path(product,
                                                                                           filter)
    end

    it "adding product properties including url filters" do
      # Given a product
      product = create(:simple_product, supplier: @supplier2)
      product.set_property('fooprop', 'fooval')

      # When I navigate to the product properties page
      visit spree.admin_product_product_properties_path(product, filter)

      # And I add a property
      select 'fooprop', from: 'product_product_properties_attributes_0_property_name'
      fill_in 'product_product_properties_attributes_0_value', with: 'fooval2'

      click_button 'Update'

      uri = URI.parse(current_url)
      expect("#{uri.path}?#{uri.query}").to eq spree.edit_admin_product_path(product, filter)
    end

    it "loading new product image page" do
      product = create(:simple_product, supplier: @supplier2)

      visit spree.admin_product_images_path(product)
      expect(page).to have_selector ".no-objects-found"

      page.find('a#new_image_link').click
      expect(page).to have_selector "#image_attachment"
    end

    it "loading new product image page including url filters" do
      product = create(:simple_product, supplier: @supplier2)

      visit spree.admin_product_images_path(product, filter)

      page.find('a#new_image_link').click

      uri = URI.parse(current_url)
      # we stay on the same url as the new image content is loaded via an ajax call
      expect("#{uri.path}?#{uri.query}").to eq spree.admin_product_images_path(product, filter)

      expected_cancel_link = Regexp.new(Regexp.escape(spree.admin_product_images_path(product,
                                                                                      filter)))
      expect(page).to have_link('Cancel', href: expected_cancel_link)
    end

    it "upload a new product image including url filters" do
      file_path = Rails.root + "spec/support/fixtures/thinking-cat.jpg"
      product = create(:simple_product, supplier: @supplier2)

      visit spree.admin_product_images_path(product, filter)

      page.find('a#new_image_link').click

      attach_file('image_attachment', file_path)
      click_button "Create"

      uri = URI.parse(current_url)
      expect("#{uri.path}?#{uri.query}").to eq spree.admin_product_images_path(product, filter)
    end

    it "loading image page including url filter" do
      product = create(:simple_product, supplier: @supplier2)

      visit spree.admin_product_images_path(product, filter)

      expected_new_image_link = Regexp.new(Regexp.escape(spree.new_admin_product_image_path(
                                                           product, filter
                                                         )))
      expect(page).to have_link('New Image', href: expected_new_image_link)
    end

    it "loading edit product image page including url filter" do
      product = create(:simple_product, supplier: @supplier2)
      image = white_logo_file
      image_object = Spree::Image.create(viewable_id: product.master.id,
                                         viewable_type: 'Spree::Variant', alt: "position 1", attachment: image, position: 1)

      visit spree.admin_product_images_path(product, filter)

      page.find("a.icon-edit").click

      uri = URI.parse(current_url)
      expect("#{uri.path}?#{uri.query}").to eq spree.edit_admin_product_image_path(product,
                                                                                   image_object, filter)

      expected_cancel_link = Regexp.new(Regexp.escape(spree.admin_product_images_path(product,
                                                                                      filter)))
      expect(page).to have_link('Cancel', href: expected_cancel_link)
      expect(page).to have_link("Back To Images List", href: expected_cancel_link)
    end

    it "updating a product image including url filter" do
      product = create(:simple_product, supplier: @supplier2)
      image = white_logo_file
      image_object = Spree::Image.create(viewable_id: product.master.id,
                                         viewable_type: 'Spree::Variant', alt: "position 1", attachment: image, position: 1)

      file_path = Rails.root + "spec/support/fixtures/thinking-cat.jpg"

      visit spree.admin_product_images_path(product, filter)

      page.find("a.icon-edit").click

      attach_file('image_attachment', file_path)
      click_button "Update"

      uri = URI.parse(current_url)
      expect("#{uri.path}?#{uri.query}").to eq spree.admin_product_images_path(product, filter)
    end

    it "checks error when creating product image with unsupported format" do
      unsupported_image_file_path = Rails.root + "README.md"
      product = create(:simple_product, supplier: @supplier2)

      image = white_logo_file
      Spree::Image.create(viewable_id: product.master.id, viewable_type: 'Spree::Variant',
                          alt: "position 1", attachment: image, position: 1)

      visit spree.admin_product_images_path(product)
      page.find('a#new_image_link').click
      attach_file('image_attachment', unsupported_image_file_path)
      click_button "Create"

      expect(page).to have_text "Attachment has an invalid content type"
      expect(page).to have_text "Please upload the image in JPG, PNG, GIF, SVG or WEBP format."
    end

    it "deleting product images" do
      product = create(:simple_product, supplier: @supplier2)
      image = white_logo_file
      Spree::Image.create(viewable_id: product.master.id, viewable_type: 'Spree::Variant',
                          alt: "position 1", attachment: image, position: 1)

      visit spree.admin_product_images_path(product)
      expect(page).to have_selector "table.index td img"
      expect(product.reload.images.count).to eq 1

      accept_alert do
        page.find('a.delete-resource').click
      end

      expect(page).to_not have_selector "table.index td img"
      expect(product.reload.images.count).to eq 0
    end

    it "deleting product image including url filter" do
      product = create(:simple_product, supplier: @supplier2)
      image = white_logo_file
      Spree::Image.create(viewable_id: product.master.id, viewable_type: 'Spree::Variant',
                          alt: "position 1", attachment: image, position: 1)

      visit spree.admin_product_images_path(product, filter)

      accept_alert do
        page.find('a.delete-resource').click
      end

      uri = URI.parse(current_url)
      expect("#{uri.path}?#{uri.query}").to eq spree.admin_product_images_path(product, filter)
    end

    context "editing a product's variant unit scale" do
      let(:product) { create(:simple_product, name: 'a product', supplier: @supplier2) }

      # TODO below -> assertions commented out refer to bug:
      # https://github.com/openfoodfoundation/openfoodnetwork/issues/7180

      before do
        allow(Spree::Config).to receive(:available_units).and_return("g,lb,oz,kg,T,mL,L,kL")
        visit spree.edit_admin_product_path product
      end

      shared_examples 'selecting a unit from dropdown' do |dropdown_option, var_unit:, var_unit_scale:|
        it 'checks if the dropdown selection is persistent' do
          select dropdown_option, from: 'product_variant_unit_with_scale'
          click_button 'Update'
          expect(flash_message).to eq('Product "a product" has been successfully updated!')
          product.reload
          expect(product.variant_unit).to eq(var_unit)
          expect(page).to have_select('product_variant_unit_with_scale', selected: dropdown_option)
          expect(product.variant_unit_scale).to eq(var_unit_scale)
        end
      end

      describe 'a shared example' do
        it_behaves_like 'selecting a unit from dropdown', 'Weight (g)', var_unit: 'weight',
                                                                        var_unit_scale: 1
        it_behaves_like 'selecting a unit from dropdown', 'Weight (kg)', var_unit: 'weight',
                                                                         var_unit_scale: 1000
        it_behaves_like 'selecting a unit from dropdown', 'Weight (T)', var_unit: 'weight',
                                                                        var_unit_scale: 1_000_000
        it_behaves_like 'selecting a unit from dropdown', 'Weight (oz)', var_unit: 'weight',
                                                                         var_unit_scale: 28.35
        it_behaves_like 'selecting a unit from dropdown', 'Weight (lb)', var_unit: 'weight',
                                                                         var_unit_scale: 453.6
        it_behaves_like 'selecting a unit from dropdown', 'Volume (mL)', var_unit: 'volume',
                                                                         var_unit_scale: 0.001
        it_behaves_like 'selecting a unit from dropdown', 'Volume (L)', var_unit: 'volume',
                                                                        var_unit_scale: 1
        it_behaves_like 'selecting a unit from dropdown', 'Volume (kL)', var_unit: 'volume',
                                                                         var_unit_scale: 1000
      end
    end
  end
end
