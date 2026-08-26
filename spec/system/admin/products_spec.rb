# frozen_string_literal: true

require "system_helper"

RSpec.describe '
    As an admin
    I want to set a supplier and distributor(s) for a product
' do
  include WebHelper
  include AuthenticationHelper
  include FileHelper

  let!(:taxon) { create(:taxon) }
  let!(:shipping_category) { DefaultShippingCategory.find_or_create }
  let!(:supplier) { create(:supplier_enterprise, name: 'New supplier') }

  describe "creating a product" do
    let!(:tax_category) { create(:tax_category, name: 'Test Tax Category') }

    before do
      login_as_admin
      visit spree.new_admin_product_path
    end

    it "display all attributes when submitting with error: no name" do
      select supplier.name, from: "Enterprise"
      select "Weight (kg)", from: 'product_variant_unit_with_scale'
      fill_in 'product_unit_value', with: "5.00 g"
      assert_selector(:field, placeholder: "5kg g")
      fill_in 'product_display_as', with: "Big Box of Chocolates"
      select taxon.name, from: "product_primary_taxon_id"
      fill_in 'product_price', with: '19.99'
      fill_in 'product_on_hand', with: 5
      check 'product_on_demand'
      select 'Test Tax Category', from: 'product_tax_category_id'
      fill_in_trix_editor 'product_description', with: 'A description...'

      click_button 'Create'

      expect(page).to have_content "Name can't be blank"
      expect(page).to have_field "Enterprise", with: supplier.id
      expect(page).to have_field 'product_unit_value', with: "5.00 g"
      expect(page).to have_field 'product_display_as', with: "Big Box of Chocolates"
      expect(page).to have_field 'product_primary_taxon_id', with: taxon.id
      expect(page).to have_field 'product_price', with: '19.99'
      expect(page).to have_field 'product_on_hand', with: 5
      expect(page).to have_field 'product_on_demand', checked: true
      expect(page).to have_field 'product_tax_category_id', with: tax_category.id
      expect(page.find("#product_description",
                       visible: false).value).to eq('<div>A description...</div>')
      expect(page.find("#product_variant_unit_field")).to have_content 'Weight (kg)'
    end

    it "display all attributes when submitting with error: Unit Value must be grater than 0" do
      select 'New supplier', from: "Enterprise"
      fill_in 'product_name', with: "new product name"
      select "Weight (kg)", from: 'product_variant_unit_with_scale'
      fill_in 'product_unit_value', with: "0.00 g"
      assert_selector(:field, placeholder: "0g g")
      fill_in 'product_display_as', with: "Big Box of Chocolates"
      select taxon.name, from: "product_primary_taxon_id"
      fill_in 'product_price', with: '19.99'
      fill_in 'product_on_hand', with: 5
      check 'product_on_demand'
      select 'Test Tax Category', from: 'product_tax_category_id'
      fill_in_trix_editor 'product_description', with: 'A description...'

      click_button 'Create'

      expect(page).to have_field 'product_name', with: "new product name"
      expect(page).to have_field "Enterprise", with: supplier.id
      expect(page).to have_field 'product_unit_value', with: "0 g"
      expect(page).to have_field 'product_display_as', with: "Big Box of Chocolates"
      expect(page).to have_field 'product_primary_taxon_id', with: taxon.id
      expect(page).to have_field 'product_price', with: '19.99'
      expect(page).to have_field 'product_on_hand', with: 5
      expect(page).to have_field 'product_on_demand', checked: true
      expect(page).to have_field 'product_tax_category_id', with: tax_category.id
      expect(page.find("#product_description",
                       visible: false).value).to eq('<div>A description...</div>')
      expect(page.find("#product_variant_unit_field")).to have_content 'Weight (kg)'

      expect(page).to have_content "Unit value must be greater than 0"
    end

    it "preserves 'Items' 'Unit Size' selection when submitting with error" do
      select "Items", from: 'product_variant_unit_with_scale'

      click_button 'Create'

      expect(page.find("#product_variant_unit_field")).to have_content 'Items'
    end

    it "assigning important attributes" do
      expect(find_field('product_shipping_category_id').text).to eq(shipping_category.name)

      select 'New supplier', from: "Enterprise"
      fill_in 'product_name', with: 'A new product !!!'
      select "Weight (kg)", from: 'product_variant_unit_with_scale'
      fill_in 'product_unit_value', with: 5
      select taxon.name, from: "product_primary_taxon_id"
      fill_in 'product_price', with: '19.99'
      fill_in 'product_on_hand', with: 5
      select 'Test Tax Category', from: 'product_tax_category_id'
      fill_in_trix_editor 'product_description', with: 'A description...'

      click_button 'Create'

      expect(current_path).to eq spree.admin_products_path
      expect(flash_message).to eq('Product "A new product !!!" has been successfully created!')

      product = Spree::Product.find_by(name: 'A new product !!!')
      variant = product.variants.first

      expect(product.description).to eq("<div>A description...</div>")
      expect(product.group_buy).to be_falsey

      expect(variant.variant_unit).to eq('weight')
      expect(variant.variant_unit_scale).to eq(1000)
      expect(variant.unit_value).to eq(5000)
      expect(variant.unit_description).to eq("")
      expect(variant.variant_unit_name).to eq("")
      expect(variant.primary_taxon_id).to eq(taxon.id)
      expect(variant.price.to_s).to eq('19.99')
      expect(variant.on_hand).to eq(5)
      expect(variant.tax_category_id).to eq(tax_category.id)
      expect(variant.shipping_category).to eq(shipping_category)
      expect(variant.unit_presentation).to eq("5kg")
      expect(variant.enterprise).to eq(supplier)
    end

    it "creating an on-demand product" do
      fill_in 'product_name', with: 'Hot Cakes'
      select 'New supplier', from: "Enterprise"
      select "Weight (kg)", from: 'product_variant_unit_with_scale'
      fill_in 'product_unit_value', with: 1
      select taxon.name, from: "product_primary_taxon_id"
      fill_in 'product_price', with: '1.99'
      fill_in 'product_on_hand', with: 0
      check 'product_on_demand'
      select 'Test Tax Category', from: 'product_tax_category_id'
      fill_in_trix_editor 'product_description',
                          with: 'In demand, and on_demand! The hottest cakes in town.'

      click_button 'Create'

      expect(current_path).to eq spree.admin_products_path
      product = Spree::Product.find_by(name: 'Hot Cakes')
      expect(product.variants.count).to eq(1)
      variant = product.variants.first
      expect(variant.on_demand).to be true
    end

    it "creating product with empty unit value" do
      fill_in 'product_name', with: 'Hot Cakes'
      select 'New supplier', from: "Enterprise"
      select "Weight (kg)", from: 'product_variant_unit_with_scale'
      fill_in "product_unit_value", with: ""
      select taxon.name, from: "product_primary_taxon_id"
      fill_in 'product_price', with: '1.99'
      fill_in 'product_on_hand', with: 0
      check 'product_on_demand'
      select 'Test Tax Category', from: 'product_tax_category_id'
      fill_in_trix_editor 'product_description',
                          with: 'In demand, and on_demand! The hottest cakes in town.'
      click_button 'Create'

      expect(current_path).to eq spree.admin_products_path
      expect(page).to have_content "Unit value can't be blank"
    end

    it "creating product with empty product category fails" do
      fill_in 'product_name', with: 'Hot Cakes'
      select 'New supplier', from: "Enterprise"
      select "Weight (kg)", from: 'product_variant_unit_with_scale'
      fill_in "product_unit_value", with: '1'
      fill_in 'product_price', with: '1.99'
      fill_in 'product_on_hand', with: 0
      check 'product_on_demand'
      select 'Test Tax Category', from: 'product_tax_category_id'
      fill_in_trix_editor 'product_description',
                          with: 'In demand, and on_demand! The hottest cakes in town.'
      click_button 'Create'

      expect(current_path).to eq spree.admin_products_path
      expect(page).to have_content "Product Category can't be blank"
    end

    it "creating product with empty product supplier fails" do
      fill_in 'product_name', with: 'Hot Cakes'
      select "Weight (kg)", from: 'product_variant_unit_with_scale'
      fill_in "product_unit_value", with: '1'
      fill_in 'product_price', with: '1.99'
      select taxon.name, from: "product_primary_taxon_id"
      fill_in 'product_on_hand', with: 0
      check 'product_on_demand'
      select 'Test Tax Category', from: 'product_tax_category_id'
      fill_in_trix_editor 'product_description',
                          with: 'In demand, and on_demand! The hottest cakes in town.'
      click_button 'Create'

      expect(current_path).to eq spree.admin_products_path
      expect(page).to have_content "Enterprise can't be blank"
    end

    describe "localization settings" do
      shared_examples "with different price values" do |localized_number, price|
        context "when enable_localized_number is set to #{localized_number}" do
          before do
            allow(Spree::Config).to receive(:enable_localized_number?).and_return(localized_number)
          end

          it "and price is #{price}" do
            fill_in 'product_name', with: 'Priceless Mangoes'
            select 'New supplier', from: "Enterprise"
            select "Weight (kg)", from: 'product_variant_unit_with_scale'
            fill_in "product_unit_value", with: 1
            select taxon.name, from: "product_primary_taxon_id"
            fill_in 'product_price', with: price.to_s
            fill_in 'product_on_hand', with: 0
            check 'product_on_demand'
            select 'Test Tax Category', from: 'product_tax_category_id'

            click_button 'Create'

            expect(current_path).to eq spree.admin_products_path

            if price.eql?("0.0")
              product = Spree::Product.find_by(name: 'Priceless Mangoes')
              expect(product.variants.count).to eq(1)
              variant = product.variants.first
              expect(variant.on_demand).to be true
              expect(variant.price).to eq 0.0 # a priceless variant gets a zero value by default
            end

            if price.eql?("")
              within "#errorExplanation" do # the banner displays the relevant error
                expect(page).to have_content "1 error prohibited this record from being saved:"
                expect(page).to have_content "Price is not a number"
              end
              within "#product_price_field" do # the form highlights the price field
                expect(page).to have_content "Price"
                expect(page).to have_content "is not a number"
              end
            end
          end
        end
      end

      context "is 0.0" do
        it_behaves_like "with different price values", false, "0.0"
        it_behaves_like "with different price values", true, "0.0"
      end

      context "is empty" do
        it_behaves_like "with different price values", false, ''
        it_behaves_like "with different price values", true, ''
      end
    end
  end

  context "as an enterprise user" do
    let!(:tax_category) { create(:tax_category) }
    let(:filter) { { producerFilter: 2 } }
    let(:image_file_path) { Rails.root.join(file_fixture_path, "thinking-cat.jpg") }
    let(:supplier2) { create(:supplier_enterprise, name: 'Another Supplier') }
    let(:supplier_permitted) { create(:supplier_enterprise, name: 'Permitted Supplier') }
    let(:new_user) { create(:user) }

    before do
      new_user.enterprise_roles.build(enterprise: supplier2).save

      login_as new_user
    end

    context "products do not require a tax category" do
      it "creating a new product" do
        create(:enterprise_relationship, parent: supplier_permitted, child: supplier2,
                                         permissions_list: [:manage_products])

        visit spree.new_admin_product_path

        fill_in 'product_name', with: 'A new product !!!'
        fill_in 'product_price', with: '19.99'

        expect(page).to have_select "Enterprise"
        select 'Another Supplier', from: "Enterprise"
        select 'Weight (g)', from: 'product_variant_unit_with_scale'
        fill_in 'product_unit_value', with: '500'
        select taxon.name, from: "product_primary_taxon_id"
        select 'None', from: "product_tax_category_id"

        # Should only have suppliers listed which the user can manage
        expect(page).to have_select "Enterprise",
                                    with_options: [supplier2.name, supplier_permitted.name]
        expect(page).not_to have_select "Enterprise", with_options: [supplier.name]

        click_button 'Create'

        expect(flash_message).to eq('Product "A new product !!!" has been successfully created!')
        product = Spree::Product.find_by(name: 'A new product !!!')
        variant = product.variants.first
        expect(variant.tax_category).to be_nil
        expect(variant.enterprise).to eq(supplier2)
      end
    end

    describe "editing page" do
      let!(:product) { create(:simple_product, name: 'a product', enterprise_id: supplier2.id) }

      describe "'Back To Products List' and 'Cancel' buttons" do
        context "navigates to edit from the bulk product update page with searched results" do
          it "should navigate back to the same searched results page" do
            # Navigating to a searched URL
            visit admin_products_url({
                                       page: 1,
                                       per_page: 25,
                                       search_term: 'product',
                                       producer_id: supplier2.id
                                     })

            products_page_url = current_url
            within row_containing_name('a product') do
              page.find(".vertical-ellipsis-menu").click
              click_link('Edit', href: spree.edit_admin_product_path(product))
            end

            expect(page).to have_link('Back To Products List',
                                      href: products_page_url)
            expect(page).to have_link('Cancel',
                                      href: products_page_url)
          end
        end

        context "directly navigates to the edit page" do
          it "should navigate back to all the products page" do
            # Navigating to a searched URL
            visit spree.edit_admin_product_path(product)

            expect(page).to have_link('Back To Products List',
                                      href: admin_products_url)
            expect(page).to have_link('Cancel',
                                      href: admin_products_url)
          end
        end
      end

      it "editing a product" do
        login_as_admin
        visit spree.edit_admin_product_path product

        fill_in_trix_editor 'product_description', with: 'A description...'

        click_button 'Update'

        expect(flash_message).to eq('Product "a product" has been successfully updated!')
        product.reload
        expect(product.description).to eq("<div>A description...</div>")

        # Product preview
        click_link 'Preview'

        within "#product-preview-modal" do
          expect(page).to have_content("Product preview")
          expect(page).to have_selector("h3 a span", text: "a product")

          click_button "Close"
        end

        expect(page).not_to have_content("Product preview")
      end

      it "editing product group buy options" do
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
        visit spree.group_buy_options_admin_product_path(product, filter)

        expected_cancel_link = Regexp.new(Regexp.escape(spree.edit_admin_product_path(product,
                                                                                      filter)))
        expect(page).to have_link('Cancel', href: expected_cancel_link)
      end

      it "editing product group buy options with url filter" do
        visit spree.group_buy_options_admin_product_path(product, filter)
        choose('product_group_buy_1')
        fill_in 'Bulk unit size', with: '10'

        click_button 'Update'

        uri = URI.parse(current_url)
        expect("#{uri.path}?#{uri.query}").to eq spree.edit_admin_product_path(product, filter)
      end

      it "editing product Search" do
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
        visit spree.seo_admin_product_path(product, filter)

        expected_cancel_link = Regexp.new(Regexp.escape(spree.edit_admin_product_path(product,
                                                                                      filter)))
        expect(page).to have_link('Cancel', href: expected_cancel_link)
      end

      it "editing product Search with url filter" do
        visit spree.seo_admin_product_path(product, filter)

        fill_in 'Product Search Keywords', with: 'Product Search Keywords'
        fill_in 'Notes', with: 'Just testing Notes'

        click_button 'Update'

        uri = URI.parse(current_url)
        expect("#{uri.path}?#{uri.query}").to eq spree.edit_admin_product_path(product, filter)
      end

      it "loading product properties page including url filters" do
        visit spree.admin_product_product_properties_path(product, filter)

        uri = URI.parse(current_url)
        # we stay on the same url as the new image content is loaded via an ajax call
        expect("#{uri.path}?#{uri.query}").to eq(
          spree.admin_product_product_properties_path(product, filter)
        )

        expected_cancel_link = Regexp.new(
          Regexp.escape(spree.admin_product_product_properties_path(product, filter))
        )
        expect(page).to have_link('Cancel', href: expected_cancel_link)
      end

      describe "image upload" do
        let!(:product) { create(:simple_product, enterprise_id: supplier2.id) }
        let(:image_subtitle) { "A square size starting from 440px by 440px is recommended." }

        it "shows the image upload prompt when no image is present" do
          visit spree.edit_admin_product_path(product)

          expect(page).to have_content image_subtitle
          expect(page).to have_content "Upload image"
        end

        it "uploads the image and navigates to the image edit page" do
          visit spree.edit_admin_product_path(product)

          attach_file "image[attachment]", white_logo_path, visible: false

          expect(page).to have_content /Image has been successfully created/
          expect(product.reload.image).to be_present
          expect(page).to have_current_path(
            spree.edit_admin_product_image_path(product, product.image)
          )
        end

        it "shows an error and stays on the page for an invalid file" do
          visit spree.edit_admin_product_path(product)

          attach_file "image[attachment]",
                      Rails.public_path.join('invalid_image.jpg'),
                      visible: false

          expect(Spree::Image.count).to eq 0
          expect(page).to have_current_path(spree.edit_admin_product_path(product))
          expect(page).to have_content "not identified as a valid media file"
        end

        it "shows the image preview when an image is present" do
          Spree::Image.create(viewable_id: product.id, viewable_type: 'Spree::Product',
                              attachment: white_logo_file, alt: "White logo")

          visit spree.edit_admin_product_path(product)

          find("img[alt='White logo']").hover

          expect(page).to have_content "Edit"
          expect(page).not_to have_content image_subtitle
        end

        it "opens the image edit page when the image tile itself is clicked" do
          image = Spree::Image.create(viewable_id: product.id, viewable_type: 'Spree::Product',
                                      attachment: white_logo_file, alt: "White logo")

          visit spree.edit_admin_product_path(product)

          find("img[alt='White logo']").click

          expect(page).to have_current_path(
            spree.edit_admin_product_image_path(product, image)
          )
          expect(page).to have_content "Edit image for"
        end
      end
    end

    describe "product properties" do
      # Given a product with a property
      let!(:product) {
        create(:simple_product, enterprise_id: supplier2.id).tap do |product|
          product.set_property('fooprop', 'fooval')
        end
      }

      it "deleting product properties" do
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
        expect(page).not_to have_field 'product_product_properties_attributes_0_value',
                                       with: 'fooval'
        expect(product.reload.property('fooprop')).to be_nil
      end

      it "deleting product properties including url filters" do
        # When I navigate to the product properties page
        visit spree.admin_product_product_properties_path(product, filter)

        # And I delete the property
        accept_alert do
          page.all('a.delete-resource').first.click
        end

        uri = URI.parse(current_url)
        expect("#{uri.path}?#{uri.query}").to eq(
          spree.admin_product_product_properties_path(product, filter)
        )
      end

      it "adding product properties including url filters" do
        # When I navigate to the product properties page
        visit spree.admin_product_product_properties_path(product, filter)

        # And I add a property
        select 'fooprop', from: 'product_product_properties_attributes_0_property_name'
        fill_in 'product_product_properties_attributes_0_value', with: 'fooval2'

        click_button 'Update'

        uri = URI.parse(current_url)
        expect("#{uri.path}?#{uri.query}").to eq spree.edit_admin_product_path(product, filter)
      end
    end

    describe "image page" do
      let!(:product) { create(:simple_product, name: 'Product A', enterprise_id: supplier2.id) }
      let(:image_subtitle) { "A square size starting from 440px by 440px is recommended." }

      it "loading image page with no image" do
        visit spree.admin_product_images_path(product)
        expect(page).to have_text "NO IMAGES FOUND"
        expect(page).to have_link "New Image"
      end

      it "hides the add image button when images are present" do
        image = white_logo_file
        Spree::Image.create(viewable_id: product.id, viewable_type: 'Spree::Product',
                            alt: "position 1", attachment: image, position: 1)

        visit spree.admin_product_images_path(product)
        expect(page).to have_selector "table.index td img"
        expect(page).not_to have_link "New Image"
      end

      it "loading edit product image page including url filter" do
        image = white_logo_file
        image_object = Spree::Image.create(viewable_id: product.id,
                                           viewable_type: 'Spree::Product', alt: "position 1",
                                           attachment: image, position: 1)

        visit spree.admin_product_images_path(product, filter)

        page.find("a.icon-edit").click

        uri = URI.parse(current_url)
        expect("#{uri.path}?#{uri.query}")
          .to eq spree.edit_admin_product_image_path(product, image_object, filter)

        expect(page).to have_link('Cancel', href: spree.edit_admin_product_path(product))
        expect(page).to have_content "Edit image for \"Product A\""
        expect(page).to have_button "Save"
      end

      it "previews a replacement file without uploading it, then saves it" do
        image_object = Spree::Image.create(viewable_id: product.id,
                                           viewable_type: 'Spree::Product', alt: "position 1",
                                           attachment: white_logo_file, position: 1)

        visit spree.edit_admin_product_image_path(product, image_object)

        expect(page).to have_content "logo-white.png"

        attach_file('image_attachment', image_file_path, make_visible: true)

        # The new file is only previewed: we stay on the page and nothing is persisted yet.
        expect(page).to have_content "thinking-cat.jpg"
        # The blob: preview must actually render; a missing CSP img-src would silently block it.
        expect(wait_until { preview_image_rendered? }).to be true
        expect(page).to have_current_path(
          spree.edit_admin_product_image_path(product, image_object)
        )
        expect(product.reload.image.attachment.filename.to_s).to eq "logo-white.png"

        click_button "Save"

        expect(page).to have_current_path spree.edit_admin_product_path(product)
        expect(product.reload.image.attachment.filename.to_s).to eq "thinking-cat.jpg"
      end

      it "updating a product image reached from a filtered list" do
        image = white_logo_file
        Spree::Image.create(viewable_id: product.id,
                            viewable_type: 'Spree::Product', alt: "position 1",
                            attachment: image, position: 1)

        visit spree.admin_product_images_path(product, filter)

        page.find("a.icon-edit").click

        attach_file('image_attachment', image_file_path, make_visible: true)
        click_button "Save"

        expect(page).to have_current_path spree.edit_admin_product_path(product)
        expect(product.reload.image.attachment.filename.to_s).to eq "thinking-cat.jpg"
      end

      it "checks error when creating product image with unsupported format" do
        unsupported_image_file_path = Rails.root.join("README.md").to_s
        product = create(:simple_product, enterprise_id: supplier2.id)

        image = white_logo_file
        Spree::Image.create(viewable_id: product.id, viewable_type: 'Spree::Product',
                            alt: "position 1", attachment: image, position: 1)

        visit spree.admin_product_images_path(product)
        page.find("a.icon-edit").click
        attach_file('image_attachment', unsupported_image_file_path, make_visible: true)
        click_button "Save"

        expect(page).to have_text "Attachment has an invalid content type"
        expect(page).to have_text "Attachment is not identified as a valid media file"
      end

      it "prefills the caption with the product name" do
        image_object = Spree::Image.create(viewable_id: product.id,
                                           viewable_type: 'Spree::Product',
                                           attachment: white_logo_file, position: 1)

        visit spree.edit_admin_product_image_path(product, image_object)

        expect(page).to have_field "image[caption]", with: product.name
      end

      it "deleting the image from the image edit page" do
        image_object = Spree::Image.create(viewable_id: product.id,
                                           viewable_type: 'Spree::Product',
                                           attachment: white_logo_file, position: 1)

        visit spree.edit_admin_product_image_path(product, image_object)

        # No confirmation dialog: the link deletes straight away.
        click_link "Delete permanently"

        expect(page).to have_current_path spree.edit_admin_product_path(product)
        expect(product.reload.image).to be_nil
        expect(page).to have_content image_subtitle
        expect(page).to have_content "Upload image"
      end

      it "editing caption and alternative text on the image edit page" do
        image_object = Spree::Image.create(viewable_id: product.id,
                                           viewable_type: 'Spree::Product',
                                           alt: "position 1",
                                           attachment: white_logo_file, position: 1)

        visit spree.edit_admin_product_image_path(product, image_object)

        expect(page).to have_field "image[caption]"
        fill_in "image[caption]", with: "Fresh asparagus"
        fill_in "image[alt]", with: "Bunch of asparagus spears"
        click_button "Save"

        expect(page).to have_current_path spree.edit_admin_product_path(product)
        expect(product.reload.image.caption).to eq "Fresh asparagus"
        expect(product.reload.image.alt).to eq "Bunch of asparagus spears"
      end

      it "clearing the caption on the image edit page" do
        image_object = Spree::Image.create(viewable_id: product.id,
                                           viewable_type: 'Spree::Product',
                                           alt: "position 1",
                                           caption: "Fresh asparagus",
                                           attachment: white_logo_file, position: 1)

        visit spree.edit_admin_product_image_path(product, image_object)

        fill_in "image[caption]", with: ""
        click_button "Save"

        expect(page).to have_current_path spree.edit_admin_product_path(product)
        expect(product.reload.image.caption).to eq ""

        # The cleared caption must not be re-prefilled with the product name.
        visit spree.edit_admin_product_image_path(product, product.reload.image)

        expect(page).to have_field "image[caption]", with: ""
      end

      it "deleting product images" do
        image = white_logo_file
        Spree::Image.create(viewable_id: product.id, viewable_type: 'Spree::Product',
                            alt: "position 1", attachment: image, position: 1)

        visit spree.admin_product_images_path(product)
        expect(page).to have_selector "table.index td img"
        expect(product.reload.image).not_to be_nil
        expect(page).not_to have_link "New Image"

        accept_alert do
          click_link "Delete"
        end

        expect(page).not_to have_selector "table.index td img"
        expect(product.reload.image).to be_nil
        expect(page).to have_link "New Image"
        expect(page).to have_text "NO IMAGES FOUND"
      end

      it "deleting product image including url filter" do
        image = white_logo_file
        Spree::Image.create(viewable_id: product.id, viewable_type: 'Spree::Product',
                            alt: "position 1", attachment: image, position: 1)

        visit spree.admin_product_images_path(product, filter)

        accept_alert do
          click_link "Delete"
        end

        uri = URI.parse(current_url)
        expect("#{uri.path}?#{uri.query}").to eq spree.admin_product_images_path(product, filter)
      end
    end
  end
end
