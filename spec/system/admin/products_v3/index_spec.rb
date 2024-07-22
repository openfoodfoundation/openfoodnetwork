# frozen_string_literal: true

require "system_helper"

RSpec.describe 'As an enterprise user, I can manage my products' do
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

  describe "listing" do
    let!(:p1) { create(:product, name: "Product1") }
    let!(:p2) { create(:product, name: "Product2") }

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
        expect(page).to have_field("_products_0_name", with: "Product1")
        expect(page).to have_field("_products_1_name", with: "Product2")
      end
    end

    it "displays a select box for suppliers, with the appropriate supplier selected" do
      pending( "[BUU] Change producer, unit type, category and tax category #11060" )
      s1 = FactoryBot.create(:supplier_enterprise)
      s2 = FactoryBot.create(:supplier_enterprise)
      s3 = FactoryBot.create(:supplier_enterprise)
      p1 = FactoryBot.create(:product, supplier_id: s2.id)
      p2 = FactoryBot.create(:product, supplier_id: s3.id)

      visit spree.admin_products_path

      expect(page).to have_select "producer_id", with_options: [s1.name, s2.name, s3.name],
                                                 selected: s2.name
      expect(page).to have_select "producer_id", with_options: [s1.name, s2.name, s3.name],
                                                 selected: s3.name
    end

    context "with several variants" do
      let!(:variant1) { p1.variants.first }
      let!(:variant2a) { p2.variants.first }
      let!(:variant2b) {
        create(:variant, display_name: "Variant2b", product: p2, on_demand: false, on_hand: 4)
      }

      before do
        variant1.update!(display_name: "Variant1", on_hand: 0, on_demand: true)
        variant2a.update!(display_name: "Variant2a", on_hand: 16, on_demand: false)
        visit spree.admin_products_path
      end

      it "displays an on hand count in a span for each product" do
        within row_containing_name "Product1" do
          expect(page).not_to have_content "20" # does not display the total stock
        end
        within row_containing_name "Variant1" do
          expect(page).to have_content "On demand"
        end

        within row_containing_name "Variant2a" do
          expect(page).to have_content "16"
        end
        within row_containing_name "Variant2b" do
          expect(page).to have_content "4"
        end
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
      let!(:product_by_supplier) {
        create(:simple_product, name: "Apples", supplier_id: producer1.id)
      }

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
end
