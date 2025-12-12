# frozen_string_literal: true

require "system_helper"

RSpec.describe 'As an enterprise user, I can update my products' do
  include AdminHelper
  include WebHelper
  include AuthenticationHelper
  include FileHelper

  let(:producer) { create(:supplier_enterprise) }
  let(:producer2) { create(:supplier_enterprise) }
  let(:user) { create(:user, enterprises: [producer, producer2]) }

  before do
    login_as user
  end

  let(:producer_search_selector) { 'input[placeholder="Search for producers"]' }
  let(:categories_search_selector) { 'input[placeholder="Search for categories"]' }
  let(:tax_categories_search_selector) { 'input[placeholder="Search for tax categories"]' }

  describe "updating", feature: :variant_tag do
    let!(:taxon) { create(:taxon) }
    let!(:variant_a1) {
      product_a.variants.first.tap{ |v|
        v.update! display_name: "Medium box", sku: "APL-01", price: 5.25, on_hand: 5,
                  on_demand: false, variant_unit: "weight", variant_unit_scale: 1
      } # Grams
    }
    let!(:product_a) {
      create(:simple_product, name: "Apples", sku: "APL-00" )
    }
    let(:variant_b1) {
      product_b.variants.first.tap{ |v|
        v.update! display_name: "Medium box", sku: "TMT-01", price: 5, on_hand: 5,
                  on_demand: false, variant_unit: "weight", variant_unit_scale: 1
      } # Grams
    }
    let(:product_b) {
      create(:simple_product, name: "Tomatoes", sku: "TMT-01")
    }
    before do
      visit admin_products_url
    end

    it "updates product and variant fields" do
      within row_containing_name("Apples") do
        fill_in "Name", with: "Pommes"
      end

      within row_containing_name("Medium box") do
        fill_in "Name", with: "Large box"
        fill_in "SKU", with: "POM-01"

        tomselect_select "Volume (mL)", from: "Unit scale"

        # Unit popout
        click_on "Unit" # activate popout
        # have to use below method to trigger the +change+ event,
        #   +fill_in "Unit value", with: ""+ does not trigger +change+ event
        find_field('Unit value').send_keys(:control, 'a', :backspace) # empty the field
        expect_browser_validation('input[aria-label="Unit value"]')

        fill_in "Unit value", with: "500.1"
        fill_in "Price", with: "10.25"

        fill_in "Tags", with: "tag one"
        find_field("Tags").send_keys(:enter) # add the tag

        # Stock popout
        click_on "On Hand" # activate popout
        fill_in "On Hand", with: "-1"
      end

      click_button "Save changes" # attempt to save or close the popout
      expect(page).to have_field "On Hand", with: "-1" # popout is still open

      fill_in "On Hand", with: "6"

      expect {
        click_button "Save changes"

        expect(page).to have_content "Changes saved"
        product_a.reload
        variant_a1.reload
      }.to change { product_a.name }.to("Pommes")
        .and change{ variant_a1.display_name }.to("Large box")
        .and change{ variant_a1.sku }.to("POM-01")
        .and change{ variant_a1.unit_value }.to(0.5001) # volumes are stored in litres
        .and change{ variant_a1.price }.to(10.25)
        .and change{ variant_a1.on_hand }.to(6)
        .and change{ variant_a1.variant_unit }.to("volume")
        .and change{ variant_a1.variant_unit_scale }.to(0.001)
        .and change{ variant_a1.tag_list }.to(["tag-one"])

      within row_containing_name("Pommes") do
        expect(page).to have_field "Name", with: "Pommes"
      end
      within row_containing_name("Large box") do
        expect(page).to have_field "Name", with: "Large box"
        expect(page).to have_field "SKU", with: "POM-01"
        expect(page).to have_button "Unit", text: "500.1mL"
        expect(page).to have_field "Price", with: "10.25"
        expect(page).to have_button "On Hand", text: "6"
      end
    end

    it "switches stock to on-demand" do
      within row_containing_name("Medium box") do
        click_on "On Hand" # activate stock popout
        check "On demand"

        expect(page).to have_button "On Hand", text: "On demand"
      end

      expect {
        click_button "Save changes"

        expect(page).to have_content "Changes saved"
        variant_a1.reload
      }.to change{ variant_a1.on_demand }.to(true)

      within row_containing_name("Medium box") do
        expect(page).to have_button "On Hand", text: "On demand"
      end
    end

    describe "Changing unit scale" do
      it "saves unit values using the new scale" do
        within row_containing_name("Medium box") do
          expect(page).to have_button "Unit", text: "1g"
          tomselect_select "Weight (kg)", from: "Unit scale"
          # New scale is visible immediately
          expect(page).to have_button "Unit", text: "1kg"
        end

        click_button "Save changes"

        expect(page).to have_content "Changes saved"
        variant_a1.reload
        expect(variant_a1.variant_unit).to eq "weight"
        expect(variant_a1.variant_unit_scale).to eq 1000 # kg
        expect(variant_a1.unit_value).to eq 1000 # 1kg

        within row_containing_name("Medium box") do
          expect(page).to have_button "Unit", text: "1kg"
        end
      end

      it "saves a custom item unit name" do
        within row_containing_name("Medium box") do
          tomselect_select "Items", from: "Unit scale"
          fill_in "Items", with: "box"
        end

        expect {
          click_button "Save changes"

          expect(page).to have_content "Changes saved"
          variant_a1.reload
        }.to change{ variant_a1.variant_unit }.to("items")
          .and change{ variant_a1.variant_unit_name }.to("box")

        within row_containing_name("Apples") do
          pending "#12005"
          expect(page).to have_content "Items (box)"
        end
      end
    end

    describe "Changing unit values" do
      # This is a rather strange feature, I wonder if anyone actually uses it.
      it "saves a variant unit description" do
        within row_containing_name("Medium box") do
          click_on "Unit" # activate popout
          fill_in "Unit value", with: "1000 boxed" # 1000 grams

          find_field("Price").click # de-activate popout
          # unit value has been parsed and displayed with unit
          expect(page).to have_button "Unit", text: "1kg boxed"
        end

        expect {
          click_button "Save changes"

          expect(page).to have_content "Changes saved"
          variant_a1.reload
        }.to change{ variant_a1.unit_value }.to(1000)
          .and change{ variant_a1.unit_description }.to("boxed")

        within row_containing_name("Medium box") do
          # New value is visible immediately
          expect(page).to have_button "Unit", text: "1kg boxed"
        end
      end

      it "saves a custom variant unit display name" do
        within row_containing_name("Medium box") do
          click_on "Unit" # activate popout
          fill_in "Display unit as", with: "250g box"
        end

        expect {
          click_button "Save changes"

          expect(page).to have_content "Changes saved"
          variant_a1.reload
        }.to change{ variant_a1.unit_to_display }.to("250g box")

        within row_containing_name("Medium box") do
          expect(page).to have_button "Unit", text: "250g box"
          click_on "Unit"
          expect(page).to have_field "Display unit as", with: "250g box"
        end
      end
    end

    # it "can select only the producers that I manage"

    it "discards changes and reloads latest data" do
      within row_containing_name("Apples") do
        fill_in "Name", with: "Pommes"
      end

      # Expect to be alerted when attempting to navigate away. Cancel.
      dismiss_confirm do
        click_link "Dashboard"
      end
      within row_containing_name("Apples") do
        expect(page).to have_field "Name", with: "Pommes" # Changed value wasn't lost
      end

      # Meanwhile, the price was updated
      variant_a1.update!(price: 10.25)

      expect {
        accept_confirm do
          click_on "Discard changes"
        end
        product_a.reload
      }.not_to change { product_a.name }

      within row_containing_name("Apples") do
        expect(page).to have_field "Name", with: "Apples" # Changed value wasn't saved
      end

      within row_containing_name("Medium box") do
        expect(page).to have_field "Price", with: "10.25" # Updated value shown
      end
    end

    context "with invalid data" do
      let!(:product_b) { create(:simple_product, name: "Bananas") }
      let(:invalid_product_name) { "A" * 256 }

      before do
        visit admin_products_url

        within row_containing_name("Apples") do
          fill_in "Name", with: invalid_product_name
        end
      end

      it "shows errors for both product and variant fields" do
        # Update variant with invalid data too
        within row_containing_name("Medium box") do
          fill_in "Name", with: "L" * 256
          fill_in "SKU", with: "1" * 256
          fill_in "Price", with: "10.25"
        end
        # Also update another product with valid data
        within row_containing_name("Bananas") do
          fill_in "Name", with: "Bananes"
        end

        expect {
          click_button "Save changes"

          expect(page).to have_content "1 product was saved correctly"
          expect(page).to have_content "1 product could not be saved"
          expect(page).to have_content "Please review the errors and try again"
          product_a.reload
        }.not_to change { product_a.name }

        # (there's no identifier displayed, so the user must remember which product it is..)
        within row_containing_name(invalid_product_name) do
          expect(page).to have_field "Name", with: invalid_product_name
          expect(page).to have_content "is too long"
        end

        pending "bug #11748"
        within row_containing_name("L" * 256) do
          expect(page).to have_field "Name", with: "L" * 256
          expect(page).to have_field "SKU", with: "1" * 256
          expect(page).to have_content "is too long"
          expect(page).to have_field "Price", with: "10.25" # other updated value is retained
        end
      end

      it "saves changes after fixing errors" do
        expect {
          click_button "Save changes"

          expect(page).to have_content("1 product could not be saved")
          product_a.reload
        }.not_to change { product_a.name }

        within row_containing_name(invalid_product_name) do
          fill_in "Name", with: "Pommes"
        end

        expect {
          click_button "Save changes"

          expect(page).to have_content "Changes saved"
          product_a.reload
          variant_a1.reload
        }.to change { product_a.name }.to("Pommes")
      end
    end

    describe "creating a new product" do
      it "redirects to the New Product page" do
        visit admin_products_url
        expect {
          click_link("New Product")
        }.to change { current_path }.to(spree.new_admin_product_path)
      end
    end

    describe "adding variants" do
      it "creates a new variant" do
        click_on "New variant"

        # find empty row for Apples
        new_variant_row = find_field("Name", placeholder: "Apples", with: "").ancestor("tr")
        expect(new_variant_row).to be_present

        within new_variant_row do
          fill_in "Name", with: "Large box"
          fill_in "SKU", with: "APL-02"

          tomselect_select("Weight (kg)", from: "Unit scale")
          click_on "Unit" # activate popout
          fill_in "Unit value", with: "1"

          fill_in "Price", with: 10.25

          click_on "On Hand" # activate popout
          fill_in "On Hand", with: "3"

          select producer.name, from: 'Producer'
          select taxon.name, from: 'Category'
        end

        expect {
          click_button "Save changes"

          expect(page).to have_content "Changes saved"
          product_a.reload
        }.to change { product_a.variants.count }.by(1)

        new_variant = product_a.variants.last
        expect(new_variant.display_name).to eq "Large box"
        expect(new_variant.sku).to eq "APL-02"
        expect(new_variant.price).to eq 10.25
        expect(new_variant.variant_unit).to eq "weight"
        expect(new_variant.unit_value).to eq 1 * 1000
        expect(new_variant.variant_unit_scale).to eq 1000
        expect(new_variant.on_hand).to eq 3
        expect(new_variant.tax_category_id).to be_nil

        within row_containing_name("Large box") do
          expect(page).to have_field "Name", with: "Large box"
          expect(page).to have_field "SKU", with: "APL-02"
          expect(page).to have_field "Price", with: "10.25"
          expect(page).to have_content "1kg"
          expect(page).to have_button "On Hand", text: "3"
          within tax_category_column do
            expect(page).to have_content "None"
          end
        end
      end

      it 'removes a newly added not persisted variant' do
        click_on "New variant"
        new_variant_row = find_field("Name", placeholder: "Apples", with: "").ancestor("tr")
        within new_variant_row do
          fill_in "Name", with: "Large box"
          fill_in "SKU", with: "APL-02"
          expect(page).to have_field("Name", placeholder: "Apples", with: "Large box")
        end

        expect(page).to have_text("1 product modified.")
        expect(page).to have_css('form.disabled-section#filters') # ie search/sort disabled

        within new_variant_row do
          page.find(".vertical-ellipsis-menu").click
          page.find('a', text: 'Remove').click
        end

        expect(page).not_to have_field("Name", placeholder: "Apples", with: "Large box")
        expect(page).not_to have_text("1 product modified.")
        expect(page).not_to have_css('form.disabled-section#filters')
      end

      it "removes newly added not persistent Variants one at a time" do
        click_on "New variant"

        first_new_variant_row = find_field("Name", placeholder: "Apples", with: "").ancestor("tr")
        within first_new_variant_row do
          fill_in "Name", with: "Large box"
        end

        click_on "New variant"
        second_new_variant_row = find_field("Name", placeholder: "Apples",
                                                    with: "").ancestor("tr")
        within second_new_variant_row do
          fill_in "Name", with: "Huge box"
        end

        expect(page).to have_text("1 product modified.")
        expect(page).to have_css('form.disabled-section#filters')

        within first_new_variant_row do
          page.find(".vertical-ellipsis-menu").click
          page.find('a', text: 'Remove').click
        end

        expect(page).to have_text("1 product modified.")

        within second_new_variant_row do
          page.find(".vertical-ellipsis-menu").click
          page.find('a', text: 'Remove').click
        end
        # Only when all non persistent variants are gone that product is non modified
        expect(page).not_to have_text("1 product modified.")
        expect(page).not_to have_css('form.disabled-section#filters')
      end

      xdescribe "producer" do
        it "can select only the producers that I manage"

        context " when I manage only one producer" do
          it "producer select doesn't show, and is saved correctly"
        end
      end

      context "With 2 products" do
        before do
          variant_b1
          # To add 2nd product on page
          page.refresh
        end

        it "removes newly added Variants across products" do
          click_on "New variant"
          apples_new_variant_row =
            find_field("Name", placeholder: "Apples", with: "").ancestor("tr")
          within apples_new_variant_row do
            fill_in "Name", with: "Large box"
          end

          tomatoes_part = page.all('tbody')[1]
          within tomatoes_part do
            click_on "New variant"
          end
          tomatoes_new_variant_row =
            find_field("Name", placeholder: "Tomatoes", with: "").ancestor("tr")
          within tomatoes_new_variant_row do
            fill_in "Name", with: "Huge box"
          end
          expect(page).to have_text("2 products modified.")
          expect(page).to have_css('form.disabled-section#filters') # ie search/sort disabled

          within apples_new_variant_row do
            page.find(".vertical-ellipsis-menu").click
            page.find('a', text: 'Remove').click
          end
          # New variant for apples is no more, expect only 1 modified product
          expect(page).to have_text("1 product modified.")
          # search/sort still disabled
          expect(page).to have_css('form.disabled-section#filters')

          within tomatoes_new_variant_row do
            page.find(".vertical-ellipsis-menu").click
            page.find('a', text: 'Remove').click
          end
          # Back to page without any alteration
          expect(page).not_to have_text("1 product modified.")
          expect(page).not_to have_css('form.disabled-section#filters')
        end
      end

      context "with invalid data" do
        let(:new_variant_row) { find_field("Name", placeholder: "Apples", with: "").ancestor("tr") }

        before do
          click_on "New variant"

          # find empty row for Apples
          expect(new_variant_row).to be_present

          within new_variant_row do
            fill_in "Name", with: "N" * 256 # too long
            fill_in "SKU", with: "n" * 256
            # didn't fill_in "Unit", can't be blank
            fill_in "Price", with: "10.25" # valid
          end
        end

        it "shows errors for both existing and new variant fields" do
          # Update existing variant with invalid data too
          within row_containing_name("Medium box") do
            fill_in "Name", with: "M" * 256
            fill_in "SKU", with: "m" * 256
            fill_in "Price", with: "10.25"
          end

          # Client side validation
          click_button "Save changes"
          within new_variant_row do
            expect_browser_validation('select[aria-label="Unit scale"]')
          end

          # Fix error
          within new_variant_row do
            tomselect_select("Weight (kg)", from: "Unit scale")
          end

          # Client side validation
          click_button "Save changes"
          within new_variant_row do
            # In CI we get "Please fill out this field." and locally we get
            # "Please fill in this field."
            expect_browser_validation('input[aria-label="Unit value"]')
          end

          # Fix error
          within new_variant_row do
            fill_in "Unit value", with: "200"
          end

          expect {
            click_button "Save changes"

            expect(page).to have_content "1 product could not be saved"
            expect(page).to have_content "Please review the errors and try again"
            variant_a1.reload
          }.not_to change { variant_a1.display_name }

          # New variant
          within row_containing_name("N" * 256) do
            expect(page).to have_field "Name", with: "N" * 256
            expect(page).to have_field "SKU", with: "n" * 256
            expect(page).to have_content "is too long"
            expect(page.find('.col-producer')).to have_content('must exist')
            expect(page.find('.col-category')).to have_content('must exist')
            expect(page).to have_field "Price", with: "10.25" # other updated value is retained
          end

          # Existing variant
          within row_containing_name("M" * 256) do
            expect(page).to have_field "Name", with: "M" * 256
            expect(page).to have_field "SKU", with: "m" * 256
            expect(page).to have_content "is too long"
          end
        end

        it "saves changes after fixing errors" do
          # Fill value to satisfy client side validation
          within new_variant_row do
            tomselect_select("Weight (kg)", from: "Unit scale")
            click_on "Unit" # activate popout
            fill_in "Unit value", with: "200"
          end

          expect {
            click_button "Save changes"

            variant_a1.reload
          }.not_to change { variant_a1.display_name }

          within row_containing_name("N" * 256) do
            fill_in "Name", with: "Nice box"
            fill_in "SKU", with: "APL-02"

            select producer.name, from: 'Producer'
            select taxon.name, from: 'Category'
          end

          expect {
            click_button "Save changes"

            expect(page).to have_content "Changes saved"
            product_a.reload
          }.to change { product_a.variants.count }.by(1)

          new_variant = product_a.variants.last
          expect(new_variant.display_name).to eq "Nice box"
          expect(new_variant.sku).to eq "APL-02"
          expect(new_variant.price).to eq 10.25
          expect(new_variant.variant_unit_scale).to eq 1000
          expect(new_variant.unit_value).to eq 200 * 1000
        end

        it "removes unsaved record" do
          # Fill value to satisfy client side validation
          within new_variant_row do
            tomselect_select("Weight (kg)", from: "Unit scale")
            click_on "Unit" # activate popout
            fill_in "Unit value", with: "200"
          end

          click_button "Save changes"

          expect(page).to have_text("1 product could not be saved.")

          within row_containing_name("N" * 256) do
            page.find(".vertical-ellipsis-menu").click
            page.find('a', text: 'Remove').click
          end

          # Now that invalid variant is removed, we can proceed to save
          click_button "Save changes"
          expect(page).not_to have_text("1 product could not be saved.")
          expect(page).not_to have_css('form.disabled-section#filters')
        end
      end
    end

    context "when only one product edited with invalid data" do
      let!(:product_b) { create(:simple_product, name: "Bananas") }

      before do
        visit admin_products_url

        within row_containing_name("Apples") do
          fill_in "Name", with: ""
        end
      end

      it "shows errors for product" do
        # Also update another product with valid data
        within row_containing_name("Bananas") do
          fill_in "Name", with: "Bananes"
        end

        expect {
          click_button "Save changes"
          product_a.reload
        }.not_to change { product_a.name }

        expect(page).not_to have_content("0 product was saved correctly, but")
        expect(page).to have_content("1 product could not be saved")
        expect(page).to have_content "Please review the errors and try again"
      end
    end

    context 'When trying to save an invalid variant with Stock value ' do
      let(:new_variant_row) { find_field("Name", placeholder: "Apples", with: "").ancestor("tr") }

      before do
        visit admin_products_url
        click_on "New variant"
      end

      it 'displays the correct value afterwards for On Hand' do
        within new_variant_row do
          fill_in "Name", with: "Large box"
          click_on "On Hand"
          fill_in "On Hand", with: "19"
          tomselect_select("Weight (kg)", from: "Unit scale")
          click_on "Unit"
          fill_in "Unit value", with: "1"
        end

        click_button "Save changes"

        expect(page).to have_content "Please review the errors and try again"
        within row_containing_name("Large box") do
          expect(page).to have_content "19"
        end
      end

      it 'displays the correct value afterwards for On demand' do
        within new_variant_row do
          fill_in "Name", with: "Large box"
          click_on "On Hand"
          check "On demand"
          tomselect_select("Weight (kg)", from: "Unit scale")
          click_on "Unit"
          fill_in "Unit value", with: "1"
        end

        click_button "Save changes"

        expect(page).to have_content "Please review the errors and try again"
        within row_containing_name("Large box") do
          expect(page).to have_content "On demand"
        end
      end
    end

    context "pagination" do
      let!(:product_a) { create(:simple_product, name: "zucchini") } # appears on p2

      it "retains selected page after saving" do
        create_products 15 # in addition to product_a
        visit admin_products_url

        within ".pagination" do
          click_on "2"
        end
        within row_containing_name("zucchini") do
          fill_in "Name", with: "zucchinis"
        end

        expect {
          click_button "Save changes"

          expect(page).to have_content "Changes saved"
          product_a.reload
        }.to change { product_a.name }.to("zucchinis")

        expect(page).to have_content "Showing 16 to 16" # todo: remove unnecessary duplication
        expect_page_to_be 2
        expect_per_page_to_be 15
        expect_products_count_to_be 1
        expect(page).to have_css row_containing_name("zucchinis")
      end
    end
  end

  describe "edit image" do
    shared_examples "updating image" do
      before do
        visit admin_products_url

        within row_containing_name("Apples") do
          click_on "Edit"
        end
      end

      it "saves product image" do
        within ".reveal-modal" do
          expect(page).to have_content "Edit product photo"
          expect_page_to_have_image(current_img_url)

          # Upload a new image file
          attach_file 'image[attachment]', Rails.public_path.join('500.jpg'), visible: false
          # It uploads automatically
        end

        expect(page).to have_content /Image has been successfully (updated|created)/
        expect(product.image.reload.url(:large)).to match /500.jpg$/

        within row_containing_name("Apples") do
          expect_page_to_have_image('500.jpg')
        end
      end

      it 'shows a modal telling not a valid image when uploading wrong type of file' do
        within ".reveal-modal" do
          attach_file 'image[attachment]',
                      Rails.public_path.join('Terms-of-service.pdf'),
                      visible: false
          expect(page).to have_content /Attachment has an invalid content type/
        end
      end

      it 'shows a modal telling not a valid image when uploading an invalid image file' do
        within ".reveal-modal" do
          attach_file 'image[attachment]',
                      Rails.public_path.join('invalid_image.jpg'),
                      visible: false
          expect(page).to have_content /Attachment is not identified as a valid media file/
        end
      end
    end

    context "with existing image" do
      let!(:product) { create(:product_with_image, name: "Apples") }
      let(:current_img_url) { product.image.url(:large) }

      include_examples "updating image"
    end

    context "with default image" do
      let!(:product) { create(:product, name: "Apples") }
      let(:current_img_url) { Spree::Image.default_image_url(:large) }

      include_examples "updating image"
    end
  end

  # Check a validation message is set, we don't check the message itself because the value is based
  # on the browser's locale.
  def expect_browser_validation(selector)
    browser_message = page.find(selector)["validationMessage"]
    expect(browser_message).to be_present
  end
end
