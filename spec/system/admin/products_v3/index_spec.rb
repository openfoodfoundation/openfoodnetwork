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
end
