# frozen_string_literal: true

require "system_helper"

RSpec.describe 'As an enterprise user, I can manage my products', feature: :admin_style_v3 do
  include AdminHelper
  include WebHelper
  include AuthenticationHelper
  include FileHelper

  let(:producer) { create(:supplier_enterprise) }
  let(:user) { create(:user, enterprises: [producer]) }

  before do
    login_as user
  end

  let(:producer_search_selector) { 'input[placeholder="Search for producers"]' }
  let(:categories_search_selector) { 'input[placeholder="Search for categories"]' }
  let(:tax_categories_search_selector) { 'input[placeholder="Search for tax categories"]' }

  describe "with no products" do
    before { visit admin_products_url }
    it "can see the new product page" do
      expect(page).to have_content "Bulk Edit Products"
      expect(page).to have_text "No products found"
      # displays buttons to add products with the correct links
      expect(page).to have_link(class: "button", text: "New Product", href: "/admin/products/new")
      expect(page).to have_link(class: "button", text: "Import multiple products",
                                href: "/admin/products/import")
    end
  end

  describe "column selector" do
    let!(:product) { create(:simple_product) }

    before do
      visit admin_products_url
    end

    it "hides column and remembers saved preference" do
      # Name shows by default
      expect(page).to have_checked_field "Name"
      expect(page).to have_selector "th", text: "Name"
      expect_other_columns_visible

      # Name is hidden
      ofn_drop_down("Columns").click
      within ofn_drop_down("Columns") do
        uncheck "Name"
      end
      expect(page).not_to have_selector "th", text: "Name"
      expect_other_columns_visible

      # Preference saved
      click_on "Save as default"
      expect(page).to have_content "Column preferences saved"
      refresh

      # Preference remembered
      ofn_drop_down("Columns").click
      within ofn_drop_down("Columns") do
        expect(page).to have_unchecked_field "Name"
      end
      expect(page).not_to have_selector "th", text: "Name"
      expect_other_columns_visible
    end

    def expect_other_columns_visible
      expect(page).to have_selector "th", text: "Producer"
      expect(page).to have_selector "th", text: "Price"
      expect(page).to have_selector "th", text: "On Hand"
    end
  end

  describe "listing" do
    let!(:p1) { create(:product) }
    let!(:p2) { create(:product) }

    before do
      visit admin_products_url
    end

    it "displays a list of products" do
      within ".products" do
        # displays table header
        expect(page).to have_selector "th", text: "Name"
        expect(page).to have_selector "th", text: "SKU"
        expect(page).to have_selector "th", text: "Unit scale"
        expect(page).to have_selector "th", text: "Unit"
        expect(page).to have_selector "th", text: "Price"
        expect(page).to have_selector "th", text: "On Hand"
        expect(page).to have_selector "th", text: "Producer"
        expect(page).to have_selector "th", text: "Category"
        expect(page).to have_selector "th", text: "Tax Category"
        expect(page).to have_selector "th", text: "Inherits Properties?"
        expect(page).to have_selector "th", text: "Actions"

        # displays product list
        expect(page).to have_selector row_containing_name(p1.name.to_s)
        expect(page).to have_selector row_containing_name(p2.name.to_s)
      end
    end

    context "with several variants" do
      let!(:variant1) { p1.variants.first }
      let!(:variant2) { p2.variants.first }
      let!(:variant3) { create(:variant, product: p2, on_demand: false, on_hand: 4) }

      before do
        variant1.update!(on_hand: 0, on_demand: true)
        variant2.update!(on_hand: 16, on_demand: false)
        visit spree.admin_products_path
      end

      it "displays an on hand count in a span for each product" do
        expect(page).to have_content "On demand"
        expect(page).not_to have_content "20" # does not display the total stock
        expect(page).to have_content "16" # displays the stock for variant_2
        expect(page).to have_content "4"  # displays the stock for variant_3
      end
    end
  end

  describe "listing" do
    let!(:p1) { create(:product) }
    let!(:p2) { create(:product) }

    before do
      visit admin_products_url
    end

    it "displays a list of products" do
      within ".products" do
        # displays table header
        expect(page).to have_selector "th", text: "Name"
        expect(page).to have_selector "th", text: "SKU"
        expect(page).to have_selector "th", text: "Unit scale"
        expect(page).to have_selector "th", text: "Unit"
        expect(page).to have_selector "th", text: "Price"
        expect(page).to have_selector "th", text: "On Hand"
        expect(page).to have_selector "th", text: "Producer"
        expect(page).to have_selector "th", text: "Category"
        expect(page).to have_selector "th", text: "Tax Category"
        expect(page).to have_selector "th", text: "Inherits Properties?"
        expect(page).to have_selector "th", text: "Actions"

        # displays product list
        expect(page).to have_field("_products_0_name", with: p1.name.to_s)
        expect(page).to have_field("_products_1_name", with: p2.name.to_s)
      end
    end

    it "displays a select box for suppliers, with the appropriate supplier selected" do
      pending( "[BUU] Change producer, unit type, category and tax category #11060" )
      s1 = FactoryBot.create(:supplier_enterprise)
      s2 = FactoryBot.create(:supplier_enterprise)
      s3 = FactoryBot.create(:supplier_enterprise)
      p1 = FactoryBot.create(:product, supplier: s2)
      p2 = FactoryBot.create(:product, supplier: s3)

      visit spree.admin_products_path

      expect(page).to have_select "producer_id", with_options: [s1.name, s2.name, s3.name],
                                                 selected: s2.name
      expect(page).to have_select "producer_id", with_options: [s1.name, s2.name, s3.name],
                                                 selected: s3.name
    end

    context "with several variants" do
      let!(:variant1) { p1.variants.first }
      let!(:variant2) { p2.variants.first }
      let!(:variant3) { create(:variant, product: p2, on_demand: false, on_hand: 4) }

      before do
        variant1.update!(on_hand: 0, on_demand: true)
        variant2.update!(on_hand: 16, on_demand: false)
        visit spree.admin_products_path
      end

      it "displays an on hand count in a span for each product" do
        expect(page).to have_content "On demand"
        expect(page).not_to have_content "20" # does not display the total stock
        expect(page).to have_content "16" # displays the stock for variant_2
        expect(page).to have_content "4"  # displays the stock for variant_3
      end
    end

    it "displays a select box for the unit of measure for the product's variants" do
      pending( "[BUU] Change producer, unit type and tax category #11060" )
      p = FactoryBot.create(:product, variant_unit: 'weight', variant_unit_scale: 1,
                                      variant_unit_name: '')

      visit spree.admin_products_path

      expect(page).to have_select "variant_unit_with_scale", selected: "Weight (g)"
    end

    it "displays a text field for the item name when unit is set to 'Items'" do
      pending( "[BUU] Change producer, unit type and tax category #11060" )
      p = FactoryBot.create(:product, variant_unit: 'items', variant_unit_scale: nil,
                                      variant_unit_name: 'packet')

      visit spree.admin_products_path

      expect(page).to have_select "variant_unit_with_scale", selected: "Items"
      expect(page).to have_field "variant_unit_name", with: "packet"
    end
  end

  describe "sorting" do
    let!(:product_b) { create(:simple_product, name: "Bananas") }
    let!(:product_a) { create(:simple_product, name: "Apples") }
    let(:products_table) { "table.products" }

    before do
      visit admin_products_url
    end

    it "Should sort products alphabetically by default in ascending order" do
      within products_table do
        # Products are in correct order.
        expect(all_input_values).to match /Apples.*Bananas/
      end
    end

    context "when clicked on 'Name' column header" do
      it "Should sort products alphabetically in descending/ascending order" do
        within products_table do
          name_header = page.find('th > a[data-column="name"]')

          # Sort in descending order
          name_header.click
          expect(page).to have_content("Name ▼") # this indicates the re-sorted content has loaded
          expect(all_input_values).to match /Bananas.*Apples/

          # Sort in ascending order
          name_header.click
          expect(page).to have_content("Name ▲") # this indicates the re-sorted content has loaded
          expect(all_input_values).to match /Apples.*Bananas/
        end
      end
    end
  end

  describe "pagination" do
    it "has a pagination, has 15 products per page by default and can change the page" do
      create_products 16
      visit admin_products_url

      expect(page).to have_selector ".pagination"
      expect_products_count_to_be 15
      within ".pagination" do
        click_on "2"
      end

      expect(page).to have_content "Showing 16 to 16" # todo: remove unnecessary duplication
      expect_page_to_be 2
      expect_per_page_to_be 15
      expect_products_count_to_be 1
    end

    it "can change the number of products per page" do
      create_products 51
      visit admin_products_url

      select "50", from: "per_page"

      expect(page).to have_content "Showing 1 to 50", wait: 10
      expect_page_to_be 1
      expect_per_page_to_be 50
      expect_products_count_to_be 50
    end
  end

  describe "search" do
    context "product has searchable term" do
      # create a product with a name that can be searched
      let!(:product_by_name) { create(:simple_product, name: "searchable product") }
      let!(:variant_a) {
        create(:variant, product_id: product_by_name.id, display_name: "Medium box")
      }
      let!(:variant_b) { create(:variant, product_id: product_by_name.id, display_name: "Big box") }

      it "can search for a product" do
        create_products 1
        visit admin_products_url

        search_for "searchable product"

        expect(page).to have_field "search_term", with: "searchable product"
        expect(page).to have_content "1 products found for your search criteria. Showing 1 to 1."
        expect_products_count_to_be 1
      end

      it "with multiple products" do
        create_products 2
        visit admin_products_url

        # returns no results, if the product does not exist
        search_for "a product which does not exist"

        expect(page).to have_field "search_term", with: "a product which does not exist"
        expect(page).to have_content "No products found for your search criteria"
        expect_products_count_to_be 0

        # returns the existing product
        search_for "searchable product"

        expect(page).to have_field "search_term", with: "searchable product"
        expect(page).to have_content "1 products found for your search criteria. Showing 1 to 1."
        expect_products_count_to_be 1
      end

      it "can search variant names" do
        create_products 1
        visit admin_products_url

        expect_products_count_to_be 2

        search_for "Big box"

        expect(page).to have_field "search_term", with: "Big box"
        expect(page).to have_content "1 products found for your search criteria. Showing 1 to 1."
        expect_products_count_to_be 1
      end

      it "reset the page when searching" do
        create_products 15
        visit admin_products_url

        within ".pagination" do
          click_on "2"
        end

        expect(page).to have_content "Showing 16 to 16"
        expect_page_to_be 2
        expect_per_page_to_be 15
        expect_products_count_to_be 1
        search_for "searchable product"
        expect(page).to have_content "1 products found for your search criteria. Showing 1 to 1."
        expect_products_count_to_be 1
      end

      it "can clear filters" do
        create_products 1
        visit admin_products_url

        search_for "searchable product"
        expect(page).to have_field "search_term", with: "searchable product"
        expect(page).to have_content "1 products found for your search criteria. Showing 1 to 1."
        expect_products_count_to_be 1
        expect(page).to have_field "Name", with: product_by_name.name

        click_link "Clear search"
        expect(page).to have_field "search_term", with: ""
        expect(page).to have_content "Showing 1 to 2"
        expect_products_count_to_be 2
      end

      it "shows a message when there are no results" do
        visit admin_products_url

        search_for "no results"
        expect(page).to have_content "No products found for your search criteria"
        expect(page).to have_link "Clear search"
      end
    end

    context "product has producer" do
      before { create_products 1 }

      # create a product with a different supplier
      let!(:producer1) { create(:supplier_enterprise, name: "Producer 1") }
      let!(:product_by_supplier) { create(:simple_product, name: "Apples", supplier: producer1) }

      before { user.enterprise_roles.create(enterprise: producer1) }

      it "can search for and update a product" do
        visit admin_products_url

        search_by_producer "Producer 1"

        # expect(page).to have_content "1 product found for your search criteria."
        expect(page).to have_select "producer_id", selected: "Producer 1", wait: 5
        expect_products_count_to_be 1

        within row_containing_name("Apples") do
          fill_in "Name", with: "Pommes"
        end

        expect {
          click_button "Save changes"

          expect(page).to have_content "Changes saved"
          product_by_supplier.reload
        }.to change { product_by_supplier.name }.to("Pommes")

        # Search is still applied
        # expect(page).to have_content "1 product found for your search criteria."
        expect(page).to have_select "producer_id", selected: "Producer 1"
        expect_products_count_to_be 1
      end
    end

    context "product has category" do
      before { create_products 1 }

      # create a product with a different category
      let!(:product_by_category) {
        create(:simple_product, primary_taxon: create(:taxon, name: "Category 1"))
      }

      it "can search for a product" do
        visit admin_products_url

        search_by_category "Category 1"

        expect(page).to have_content "1 products found for your search criteria. Showing 1 to 1."
        expect(page).to have_select "category_id", selected: "Category 1"
        expect_products_count_to_be 1
        expect(page).to have_field "Name", with: product_by_category.name
      end
    end
  end

  describe "columns"

  describe "updating" do
    let!(:variant_a1) {
      product_a.variants.first.tap{ |v|
        v.update! display_name: "Medium box", sku: "APL-01", price: 5.25, on_hand: 5,
                  on_demand: false
      }
    }
    let!(:product_a) {
      create(:simple_product, name: "Apples", sku: "APL-00",
                              variant_unit: "weight", variant_unit_scale: 1) # Grams
    }
    let(:variant_b1) {
      product_b.variants.first.tap{ |v|
        v.update! display_name: "Medium box", sku: "TMT-01", price: 5, on_hand: 5,
                  on_demand: false
      }
    }
    let(:product_b) {
      create(:simple_product, name: "Tomatoes", sku: "TMT-01",
                              variant_unit: "weight", variant_unit_scale: 1) # Grams
    }
    before do
      visit admin_products_url
    end

    it "updates product and variant fields" do
      within row_containing_name("Apples") do
        fill_in "Name", with: "Pommes"
        fill_in "SKU", with: "POM-00"
        tomselect_select "Volume (mL)", from: "Unit scale"
      end
      within row_containing_name("Medium box") do
        fill_in "Name", with: "Large box"
        fill_in "SKU", with: "POM-01"

        click_on "Unit" # activate popout
      end

      # Unit popout
      fill_in "Unit value", with: ""
      click_button "Save changes" # attempt to save or close the popout
      expect(page).to have_field "Unit value", with: "" # popout is still open
      fill_in "Unit value", with: "500.1"

      within row_containing_name("Medium box") do
        fill_in "Price", with: "10.25"

        click_on "On Hand" # activate popout
      end

      # Stock popout
      fill_in "On Hand", with: "-1"
      click_button "Save changes" # attempt to save or close the popout
      expect(page).to have_field "On Hand", with: "-1" # popout is still open
      fill_in "On Hand", with: "6"

      expect {
        click_button "Save changes"

        expect(page).to have_content "Changes saved"
        product_a.reload
        variant_a1.reload
      }.to change { product_a.name }.to("Pommes")
        .and change{ product_a.sku }.to("POM-00")
        .and change{ product_a.variant_unit }.to("volume")
        .and change{ product_a.variant_unit_scale }.to(0.001)
        .and change{ variant_a1.display_name }.to("Large box")
        .and change{ variant_a1.sku }.to("POM-01")
        .and change{ variant_a1.unit_value }.to(0.5001) # volumes are stored in litres
        .and change{ variant_a1.price }.to(10.25)
        .and change{ variant_a1.on_hand }.to(6)

      within row_containing_name("Pommes") do
        expect(page).to have_field "Name", with: "Pommes"
        expect(page).to have_field "SKU", with: "POM-00"
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
        end
        within row_containing_name("Apples") do
          tomselect_select "Weight (kg)", from: "Unit scale"
        end
        within row_containing_name("Medium box") do
          # New scale is visible immediately
          expect(page).to have_button "Unit", text: "1kg"
        end

        click_button "Save changes"

        expect(page).to have_content "Changes saved"
        product_a.reload
        expect(product_a.variant_unit).to eq "weight"
        expect(product_a.variant_unit_scale).to eq 1000 # kg
        expect(variant_a1.reload.unit_value).to eq 1000 # 1kg

        within row_containing_name("Medium box") do
          expect(page).to have_button "Unit", text: "1kg"
        end
      end

      it "saves a custom item unit name" do
        within row_containing_name("Apples") do
          tomselect_select "Items", from: "Unit scale"
          fill_in "Items", with: "box"
        end

        expect {
          click_button "Save changes"

          expect(page).to have_content "Changes saved"
          product_a.reload
        }.to change{ product_a.variant_unit }.to("items")
          .and change{ product_a.variant_unit_name }.to("box")

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

      # Meanwhile, the SKU was updated
      product_a.update! sku: "APL-10"

      expect {
        accept_confirm do
          click_on "Discard changes"
        end
        product_a.reload
      }.not_to change { product_a.name }

      within row_containing_name("Apples") do
        expect(page).to have_field "Name", with: "Apples" # Changed value wasn't saved
        expect(page).to have_field "SKU", with: "APL-10" # Updated value shown
      end
    end

    context "with invalid data" do
      let!(:product_b) { create(:simple_product, name: "Bananas") }

      before do
        visit admin_products_url

        within row_containing_name("Apples") do
          fill_in "Name", with: ""
          fill_in "SKU", with: "A" * 256
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
        within row_containing_name("") do
          expect(page).to have_field "Name", with: ""
          expect(page).to have_content "can't be blank"
          expect(page).to have_field "SKU", with: "A" * 256
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

        within row_containing_name("") do
          fill_in "Name", with: "Pommes"
          fill_in "SKU", with: "POM-00"
        end

        expect {
          click_button "Save changes"

          expect(page).to have_content "Changes saved"
          product_a.reload
          variant_a1.reload
        }.to change { product_a.name }.to("Pommes")
          .and change{ product_a.sku }.to("POM-00")
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

          click_on "Unit" # activate popout
          fill_in "Unit value", with: "1000"

          fill_in "Price", with: 10.25

          click_on "On Hand" # activate popout
          fill_in "On Hand", with: "3"
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
        expect(new_variant.unit_value).to eq 1000
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
        second_new_variant_row = find_field("Name", placeholder: "Apples", with: "").ancestor("tr")
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
        before do
          click_on "New variant"

          # find empty row for Apples
          new_variant_row = find_field("Name", placeholder: "Apples", with: "").ancestor("tr")
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
            expect(page.find_button("Unit")).to have_text "" # have_button selector don't work here
            expect(page).to have_content "can't be blank"
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
          expect {
            click_button "Save changes"

            variant_a1.reload
          }.not_to change { variant_a1.display_name }

          within row_containing_name("N" * 256) do
            fill_in "Name", with: "Nice box"
            fill_in "SKU", with: "APL-02"

            click_on "Unit" # activate popout
            fill_in "Unit value", with: "200"
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
          expect(new_variant.unit_value).to eq 200
        end

        it "removes unsaved record" do
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
          fill_in "SKU", with: "A" * 256
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

  describe "Changing producers, category and tax category" do
    let!(:variant_a1) {
      product_a.variants.first.tap{ |v|
        v.update! display_name: "Medium box", sku: "APL-01", price: 5.25, on_hand: 5,
                  on_demand: false
      }
    }
    let!(:product_a) {
      create(:simple_product, name: "Apples", sku: "APL-00",
                              variant_unit: "weight", variant_unit_scale: 1) # Grams
    }

    context "when they are under 11" do
      before do
        create_list(:supplier_enterprise, 9, users: [user])
        create_list(:tax_category, 9)
        create_list(:taxon, 2)

        visit admin_products_url
      end

      it "should not display search input, change the producers, category and tax category" do
        producer_to_select = random_producer(product_a)
        category_to_select = random_category(variant_a1)
        tax_category_to_select = random_tax_category

        within row_containing_name(product_a.name) do
          validate_tomselect_without_search!(
            page, "Producer",
            producer_search_selector
          )
          tomselect_select(producer_to_select, from: "Producer")
        end

        within row_containing_name(variant_a1.display_name) do
          validate_tomselect_without_search!(
            page, "Category",
            categories_search_selector
          )
          tomselect_select(category_to_select, from: "Category")

          validate_tomselect_without_search!(
            page, "Tax Category",
            tax_categories_search_selector
          )
          tomselect_select(tax_category_to_select, from: "Tax Category")
        end

        click_button "Save changes"

        expect(page).to have_content "Changes saved"
        product_a.reload
        variant_a1.reload

        expect(product_a.supplier.name).to eq(producer_to_select)
        expect(variant_a1.primary_taxon.name).to eq(category_to_select)
        expect(variant_a1.tax_category.name).to eq(tax_category_to_select)
      end
    end

    context "when they are over 11" do
      before do
        create_list(:supplier_enterprise, 11, users: [user])
        create_list(:tax_category, 11)
        create_list(:taxon, 11)

        visit admin_products_url
      end

      it "should display search input, change the producer" do
        producer_to_select = random_producer(product_a)
        category_to_select = random_category(variant_a1)
        tax_category_to_select = random_tax_category

        within row_containing_name(product_a.name) do
          validate_tomselect_with_search!(
            page, "Producer",
            producer_search_selector
          )
          tomselect_search_and_select(producer_to_select, from: "Producer")
        end

        within row_containing_name(variant_a1.display_name) do
          sleep(0.1)
          validate_tomselect_with_search!(
            page, "Category",
            categories_search_selector
          )
          tomselect_search_and_select(category_to_select, from: "Category")

          sleep(0.1)
          validate_tomselect_with_search!(
            page, "Tax Category",
            tax_categories_search_selector
          )
          tomselect_search_and_select(tax_category_to_select, from: "Tax Category")
        end

        click_button "Save changes"

        expect(page).to have_content "Changes saved"
        product_a.reload
        variant_a1.reload

        expect(product_a.supplier.name).to eq(producer_to_select)
        expect(variant_a1.primary_taxon.name).to eq(category_to_select)
        expect(variant_a1.tax_category.name).to eq(tax_category_to_select)
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

      it 'shows a modal telling not a valid image when uploading a non valid image file' do
        within ".reveal-modal" do
          attach_file 'image[attachment]',
                      Rails.public_path.join('invalid_image.jpg'),
                      visible: false
          expect(page).to have_content /Attachment is not a valid image/
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

  describe "actions" do
    describe "edit" do
      let!(:variant_a1) {
        create(:variant,
               product: product_a,
               display_name: "Medium box",
               sku: "APL-01",
               price: 5.25)
      }
      let!(:product_a) { create(:simple_product, name: "Apples", sku: "APL-00") }

      before do
        visit admin_products_url
      end

      it "shows an actions menu with an edit link for product and variant" do
        within row_containing_name("Apples") do
          page.find(".vertical-ellipsis-menu").click
          expect(page).to have_link "Edit", href: spree.edit_admin_product_path(product_a)
        end

        within row_containing_name("Medium box") do
          page.find(".vertical-ellipsis-menu").click
          expect(page).to have_link "Edit",
                                    href: spree.edit_admin_product_variant_path(product_a,
                                                                                variant_a1)
        end
      end
    end

    describe "clone" do
      let!(:variant_a1) {
        create(:variant,
               product: product_a,
               display_name: "Medium box",
               sku: "APL-01",
               price: 5.25)
      }
      let(:product_a) { create(:simple_product, name: "Apples", sku: "APL-00") }

      before do
        visit admin_products_url
      end

      describe "Actions columns (clone)" do
        it "shows an actions menu with a clone link when clicking on icon for product" do
          within row_containing_name("Apples") do
            page.find(".vertical-ellipsis-menu").click
            expect(page).to have_link "Clone", href: admin_clone_product_path(product_a)
          end

          within row_containing_name("Medium box") do
            page.find(".vertical-ellipsis-menu").click
            expect(page).not_to have_link "Clone", href: admin_clone_product_path(product_a)
          end
        end
      end

      describe "Cloning product" do
        it "shows the cloned product on page when clicked on the cloned option" do
          within "table.products" do
            # Gather input values, because page.content doesn't include them.
            input_content = page.find_all('input[type=text]').map(&:value).join

            # Products does not include the cloned product.
            expect(input_content).not_to match /COPY OF Apples/
          end

          click_product_clone "Apples"

          expect(page).to have_content "Successfully cloned the product"
          within "table.products" do
            # Gather input values, because page.content doesn't include them.
            input_content = page.find_all('input[type=text]').map(&:value).join

            # Products include the cloned product.
            expect(input_content).to match /COPY OF Apples/
          end
        end

        it "shows error message when cloning invalid record" do
          # Existing product is invalid:
          product_a.update_columns(variant_unit: nil)

          click_product_clone "Apples"

          expect(page).to have_content "Unable to clone the product"

          within "table.products" do
            # Products does not include the cloned product.
            expect(all_input_values).not_to match /COPY OF Apples/
          end
        end
      end
    end

    describe "delete" do
      let!(:product_a) { create(:simple_product, name: "Apples", sku: "APL-00") }
      let(:delete_option_selector) { "a[data-controller='modal-link'].delete" }
      let(:product_selector) { row_containing_name("Apples") }
      let(:variant_selector) { row_containing_name("Medium box") }
      let(:default_variant_selector) {
        "tr:has(input[aria-label=Price][value='#{product_a.price}'])"
      }

      describe "Actions columns (delete)" do
        before do
          visit admin_products_url
        end

        it "shows an actions menu with a delete link when clicking on icon for product. " \
           "doesn't show delete link for the single variant" do
          within product_selector do
            page.find(".vertical-ellipsis-menu").click
            expect(page).to have_css(delete_option_selector)
          end
          page.find("div#content").click # to close the vertical actions menu

          # to select the default variant
          within default_variant_selector do
            page.find(".vertical-ellipsis-menu").click
            expect(page).not_to have_css(delete_option_selector)
          end
        end

        it "shows an actions menu with a delete link when clicking on icon for variant " \
           "if have multiple" do
          create(:variant,
                 product: product_a,
                 display_name: "Medium box",
                 sku: "APL-01",
                 price: 5.25)
          visit admin_products_url

          # to select the default variant
          within default_variant_selector do
            page.find(".vertical-ellipsis-menu").click
            expect(page).to have_css(delete_option_selector)
          end
          page.find("div#content").click # to close the vertical actions menu

          within variant_selector do
            page.find(".vertical-ellipsis-menu").click
            expect(page).to have_css(delete_option_selector)
          end
        end
      end

      describe "Delete Action" do
        let!(:variant_a1) {
          create(:variant,
                 product: product_a,
                 display_name: "Medium box",
                 sku: "APL-01",
                 price: 5.25)
        }
        let(:modal_selector) { "div[data-modal-target=modal]" }
        let(:dismiss_button_selector) { "button[data-action='click->flash#close']" }

        context "when 'keep product/variant' is selected" do
          it 'should not delete the product/variant' do
            visit admin_products_url

            # Keep Product
            within product_selector do
              page.find(".vertical-ellipsis-menu").click
              page.find(delete_option_selector).click
            end
            keep_button_selector = "input[type=button][value='Keep product']"
            within modal_selector do
              page.find(keep_button_selector).click
            end

            expect(page).not_to have_selector(modal_selector)
            expect(page).to have_selector(product_selector)

            # Keep Variant
            within variant_selector do
              page.find(".vertical-ellipsis-menu").click
              page.find(delete_option_selector).click
            end
            keep_button_selector = "input[type=button][value='Keep variant']"
            within modal_selector do
              page.find(keep_button_selector).click
            end

            expect(page).not_to have_selector(modal_selector)
            expect(page).to have_selector(variant_selector)
          end
        end

        context "when 'delete product/variant' is selected" do
          let(:success_flash_message_selector) { "div.flash.success" }
          let(:error_flash_message_selector) { "div.flash.error" }
          it 'should successfully delete the product/variant' do
            visit admin_products_url
            # Delete Variant
            within variant_selector do
              page.find(".vertical-ellipsis-menu").click
              page.find(delete_option_selector).click
            end

            delete_button_selector = "input[type=button][value='Delete variant']"
            within modal_selector do
              page.find(delete_button_selector).click
            end

            expect(page).not_to have_selector(modal_selector)
            expect(page).not_to have_selector(variant_selector)
            within success_flash_message_selector do
              expect(page).to have_content("Successfully deleted the variant")
              page.find(dismiss_button_selector).click
            end

            # Delete product
            within product_selector do
              page.find(".vertical-ellipsis-menu").click
              page.find(delete_option_selector).click
            end
            delete_button_selector = "input[type=button][value='Delete product']"
            within modal_selector do
              page.find(delete_button_selector).click
            end
            expect(page).not_to have_selector(modal_selector)
            expect(page).not_to have_selector(product_selector)
            within success_flash_message_selector do
              expect(page).to have_content("Successfully deleted the product")
            end
          end

          it 'should be failed to delete the product/variant' do
            visit admin_products_url
            allow_any_instance_of(Spree::Product).to receive(:destroy).and_return(false)
            allow_any_instance_of(Spree::Variant).to receive(:destroy).and_return(false)

            # Delete Variant
            within variant_selector do
              page.find(".vertical-ellipsis-menu").click
              page.find(delete_option_selector).click
            end

            delete_button_selector = "input[type=button][value='Delete variant']"
            within modal_selector do
              page.find(delete_button_selector).click
            end

            within error_flash_message_selector do
              expect(page).to have_content("Unable to delete the variant")
              page.find(dismiss_button_selector).click
            end

            # Delete product
            within product_selector do
              page.find(".vertical-ellipsis-menu").click
              page.find(delete_option_selector).click
            end
            delete_button_selector = "input[type=button][value='Delete product']"
            within modal_selector do
              page.find(delete_button_selector).click
            end
            within error_flash_message_selector do
              expect(page).to have_content("Unable to delete the product")
            end
          end
        end

        context 'a shipped product' do
          let!(:order) { create(:shipped_order, line_items_count: 1) }
          let!(:line_item) { order.reload.line_items.first }

          context "a deleted line item from a shipped order" do
            before do
              login_as_admin
              visit admin_products_url

              # Delete Variant
              within variant_selector do
                page.find(".vertical-ellipsis-menu").click
                page.find(delete_option_selector).click
              end

              delete_button_selector = "input[type=button][value='Delete variant']"
              within modal_selector do
                page.find(delete_button_selector).click
              end
            end

            it 'keeps the line item on the order (admin)' do
              visit spree.edit_admin_order_path(order)

              expect(page).to have_content(line_item.product.name.to_s)
            end
          end
        end
      end
    end
  end

  context "as an enterprise manager" do
    let(:supplier_managed1) { create(:supplier_enterprise, name: 'Supplier Managed 1') }
    let(:supplier_managed2) { create(:supplier_enterprise, name: 'Supplier Managed 2') }
    let(:supplier_unmanaged) { create(:supplier_enterprise, name: 'Supplier Unmanaged') }
    let(:supplier_permitted) { create(:supplier_enterprise, name: 'Supplier Permitted') }
    let(:distributor_managed) { create(:distributor_enterprise, name: 'Distributor Managed') }
    let(:distributor_unmanaged) { create(:distributor_enterprise, name: 'Distributor Unmanaged') }
    let!(:product_supplied) { create(:product, supplier: supplier_managed1, price: 10.0) }
    let!(:product_not_supplied) { create(:product, supplier: supplier_unmanaged) }
    let!(:product_supplied_permitted) {
      create(:product, name: 'Product Permitted', supplier: supplier_permitted, price: 10.0)
    }
    let(:product_supplied_inactive) {
      create(:product, supplier: supplier_managed1, price: 10.0)
    }

    let!(:supplier_permitted_relationship) do
      create(:enterprise_relationship, parent: supplier_permitted, child: supplier_managed1,
                                       permissions_list: [:manage_products])
    end

    before do
      enterprise_user = create(:user)
      enterprise_user.enterprise_roles.build(enterprise: supplier_managed1).save
      enterprise_user.enterprise_roles.build(enterprise: supplier_managed2).save
      enterprise_user.enterprise_roles.build(enterprise: distributor_managed).save

      login_as enterprise_user
    end

    it "shows only products that I supply" do
      visit spree.admin_products_path

      # displays permitted product list only
      expect(page).to have_selector row_containing_name(product_supplied.name)
      expect(page).to have_selector row_containing_name(product_supplied_permitted.name)
      expect(page).not_to have_selector row_containing_name(product_not_supplied.name)
    end

    it "shows only suppliers that I manage or have permission to" do
      visit spree.admin_products_path
      within row_containing_name(product_supplied.name) do
        expect(page).to have_select(
          '_products_0_supplier_id',
          options: [
            supplier_managed1.name, supplier_managed2.name, supplier_permitted.name
          ], selected: supplier_managed1.name
        )
      end

      within row_containing_name(product_supplied_permitted.name) do
        expect(page).to have_select(
          '_products_1_supplier_id',
          options: [
            supplier_managed1.name, supplier_managed2.name, supplier_permitted.name
          ], selected: supplier_permitted.name
        )
      end
    end

    it "shows inactive products that I supply" do
      product_supplied_inactive

      visit spree.admin_products_path

      expect(page).to have_selector row_containing_name(product_supplied_inactive.name)
    end

    it "allows me to update a product" do
      visit spree.admin_products_path

      within row_containing_name(product_supplied.name) do
        fill_in "Name", with: "Pommes"
      end
      click_button "Save changes"

      expect(page).to have_content "Changes saved"
      expect(page).to have_selector row_containing_name("Pommes")
    end
  end

  describe "creating a new product" do
    let!(:stock_location) { create(:stock_location, backorderable_default: false) }
    let!(:supplier) { create(:supplier_enterprise) }
    let!(:distributor) { create(:distributor_enterprise) }
    let!(:shipping_category) { create(:shipping_category) }
    let!(:taxon) { create(:taxon) }

    before do
      login_as_admin
      visit spree.admin_products_path
    end

    it "creating a new product" do
      find("a", text: "New Product").click
      expect(page).to have_content "New Product"
      fill_in 'product_name', with: 'Big Bag Of Apples'
      tomselect_select supplier.name, from: 'product[supplier_id]'
      select_tom_select 'Weight (g)', from: 'product_variant_unit_field'
      fill_in 'product_unit_value', with: '100'
      fill_in 'product_price', with: '10.00'
      # TODO dropdowns below are still using select2:
      select taxon.name, from: 'product_primary_taxon_id' # ...instead of tom-select
      select shipping_category.name, from: 'product_shipping_category_id' # ...instead of tom-select
      click_button 'Create'
      expect(URI.parse(current_url).path).to eq spree.admin_products_path
      expect(flash_message).to eq 'Product "Big Bag Of Apples" has been successfully created!'
      expect(page).to have_field "_products_0_name", with: 'Big Bag Of Apples'
    end
  end

  context "creating new variants" do
    let!(:product) { create(:product, variant_unit: 'weight', variant_unit_scale: 1000) }

    before do
      login_as_admin
      visit spree.admin_products_path
    end

    it "hovering over the New variant button displays the text" do
      page.find('button[aria-label="New variant"]', text: "New variant", visible: false)
      find("button.secondary.condensed.naked.icon-plus").hover
      page.find('button[aria-label="New variant"]', text: "New variant", visible: true)
      expect(page).to have_content "New variant"
    end

    shared_examples "creating a new variant (bulk)" do |stock|
      it "handles the #{stock} behaviour" do
        # the product and the default variant is displayed
        expect(page).to have_selector("input[aria-label=Name][value='#{product.name}']",
                                      visible: true, count: 1)
        expect(page).to have_selector("input[aria-label=Name][placeholder='#{product.name}']",
                                      visible: false, count: 1)

        # when a second variant is added, the number of lines increases
        expect {
          find("button.secondary.condensed.naked.icon-plus").click
        }.to change{
          page.all("input[aria-label=Name][placeholder='#{product.name}']", visible: false).count
        }.from(1).to(2)

        # When I fill out variant details and hit update
        within page.all("tr.condensed")[1] do # selects second variant row
          find('input[id$="_sku"]').fill_in with: "345"
          find('input[id$="_display_name"]').fill_in with: "Small bag"
          find('button[id$="unit_to_display"]').click # opens the unit value pop out
          find('input[id$="_unit_value_with_description"]').fill_in with: "0.002"
          find('input[id$="_display_as"]').fill_in with: "2 grams"
          find('button[aria-label="On Hand"]').click
          find('input[id$="_price"]').fill_in with: "11.1"
          if stock == "on_hand"
            find('input[id$="_on_hand"]').fill_in with: "66"
          elsif stock == "on_demand"
            find('input[id$="_on_demand"]').check
          end
        end

        expect(page).to have_content "1 product modified."

        expect {
          click_on "Save changes"
          expect(page).to have_content "Changes saved"
        }.to change {
               Spree::Variant.count
             }.from(1).to(2)

        click_on "Dismiss"
        expect(page).not_to have_content "Changes saved"

        new_variant = Spree::Variant.where(deleted_at: nil).last
        expect(new_variant.sku).to eq "345"
        expect(new_variant.display_name).to eq "Small bag"
        expect(new_variant.unit_value).to eq 2.0
        expect(new_variant.display_as).to eq "2 grams"
        expect(new_variant.unit_presentation).to eq "2 grams"
        expect(new_variant.price).to eq 11.1
        if stock == "on_hand"
          expect(new_variant.on_hand).to eq 66
        elsif stock == "on_demand"
          expect(new_variant.on_demand).to eq true
        end

        within page.all("tr.condensed")[1] do # selects second variant row
          page.find('input[id$="_sku"]').fill_in with: "789"
        end

        accept_confirm do
          click_on "Discard changes" # does not save chages
        end
        expect(page).not_to have_content "Changes saved"
      end
    end

    it_behaves_like "creating a new variant (bulk)", "on_hand"
    it_behaves_like "creating a new variant (bulk)", "on_demand"
  end

  def create_products(amount)
    amount.times do |i|
      create(:simple_product, name: "product #{i}", supplier: producer)
    end
  end

  def expect_page_to_be(page_number)
    expect(page).to have_selector ".pagination .page.current", text: page_number.to_s
  end

  def expect_per_page_to_be(per_page)
    expect(page).to have_selector "#per_page", text: per_page.to_s
  end

  def expect_products_count_to_be(count)
    expect(page).to have_selector("table.products tbody", count:)
  end

  def search_for(term)
    fill_in "search_term", with: term
    click_button "Search"
  end

  def search_by_producer(producer)
    tomselect_select producer, from: "producer_id"
    click_button "Search"
  end

  def search_by_category(category)
    tomselect_select category, from: "category_id"
    click_button "Search"
  end

  # Selector for table row that has an input with this value.
  # Because there are no visible labels, the user has to assume which product it is, based on the
  # visible name.
  def row_containing_name(value)
    "tr:has(input[aria-label=Name][value='#{value}'])"
  end

  # Wait for an element with the given CSS selector and class to be present
  def wait_for_class(selector, class_name)
    max_wait_time = Capybara.default_max_wait_time
    Timeout.timeout(max_wait_time) do
      sleep(0.1) until page.has_css?(selector, class: class_name, visible: false)
    end
  end

  def expect_page_to_have_image(url)
    expect(page).to have_selector("img[src$='#{url}']")
  end

  def tax_category_column
    @tax_category_column ||= '[data-controller="variant"] > td:nth-child(10)'
  end

  def validate_tomselect_without_search!(page, field_name, search_selector)
    open_tomselect_to_validate!(page, field_name) do
      expect(page).not_to have_selector(search_selector)
    end
  end

  def validate_tomselect_with_search!(page, field_name, search_selector)
    open_tomselect_to_validate!(page, field_name) do
      expect(page).to have_selector(search_selector)
    end
  end

  def random_producer(product)
    Enterprise.is_primary_producer
      .where.not(id: product.supplier.id)
      .pluck(:name).sample
  end

  def random_category(variant)
    Spree::Taxon
      .where.not(id: variant.primary_taxon.id)
      .pluck(:name).sample
  end

  def random_tax_category
    Spree::TaxCategory
      .pluck(:name).sample
  end

  def all_input_values
    page.find_all('input[type=text]').map(&:value).join
  end

  def click_product_clone(product_name)
    within row_containing_name(product_name) do
      page.find(".vertical-ellipsis-menu").click
      click_link('Clone')
    end
  end
end
