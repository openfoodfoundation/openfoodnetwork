# frozen_string_literal: true

require "system_helper"

describe 'As an admin, I can see the new product page' do
  include WebHelper
  include AuthenticationHelper
  include FileHelper

  # create lot of products
  70.times do |i|
    let!("product_#{i}".to_sym) { create(:simple_product, name: "product #{i}") }
  end

  before do
    # activate feature toggle admin_style_v3 to use new admin interface
    Flipper.enable(:admin_style_v3)
    login_as_admin
  end

  it "can see the new product page" do
    visit admin_products_v3_index_url
    expect(page).to have_content "Bulk Edit Products"
  end

  describe "sorting" do
    let!(:product_b) { create(:simple_product, name: "Bananas") }
    let!(:product_a) { create(:simple_product, name: "Apples") }

    before do
      visit admin_products_v3_index_url
    end

    it "Should sort products alphabetically by default" do
      within "table.products" do
        # Gather input values, because page.content doesn't include them.
        input_content = page.find_all('input[type=text]').map(&:value).join

        # Products are in correct order.
        expect(input_content).to match /Apples.*Bananas/
      end
    end
  end

  describe "pagination" do
    before do
      visit admin_products_v3_index_url
    end

    it "has a pagination, has 15 products per page by default and can change the page" do
      expect(page).to have_selector ".pagination"
      expect_products_count_to_be 15
      within ".pagination" do
        click_link "2"
      end

      expect(page).to have_content "Showing 16 to 30"
      expect_page_to_be 2
      expect_per_page_to_be 15
      expect_products_count_to_be 15
    end

    it "can change the number of products per page" do
      select "50", from: "per_page"

      expect(page).to have_content "Showing 1 to 50"
      expect_page_to_be 1
      expect_per_page_to_be 50
      expect_products_count_to_be 50
    end
  end

  describe "search" do
    context "product has searchable term" do
      # create a product with a name that can be searched
      let!(:product_by_name) { create(:simple_product, name: "searchable product") }

      before do
        visit admin_products_v3_index_url
      end

      it "can search for a product" do
        search_for "searchable product"

        expect(page).to have_field "search_term", with: "searchable product"
        # expect(page).to have_content "1 product found for your search criteria."
        expect_products_count_to_be 1
      end

      it "reset the page when searching" do
        within ".pagination" do
          click_link "2"
        end

        expect(page).to have_content "Showing 16 to 30"
        expect_page_to_be 2
        expect_per_page_to_be 15
        expect_products_count_to_be 15
        search_for "searchable product"
        # expect(page).to have_content "1 product found for your search criteria."
        expect_products_count_to_be 1
      end

      it "can clear filters" do
        search_for "searchable product"
        expect(page).to have_field "search_term", with: "searchable product"
        # expect(page).to have_content "1 product found for your search criteria."
        expect_products_count_to_be 1
        expect(page).to have_field "Name", with: product_by_name.name

        click_link "Clear search"
        expect(page).to have_field "search_term", with: ""
        expect(page).to have_content "Showing 1 to 15"
        expect_page_to_be 1
        expect_products_count_to_be 15
      end

      it "shows a message when there are no results" do
        search_for "no results"
        expect(page).to have_content "No products found for your search criteria"
        expect(page).to have_link "Clear search"
      end
    end

    context "product has producer" do
      # create a product with a supplier that can be searched
      let!(:producer) { create(:supplier_enterprise, name: "Producer 1") }
      let!(:product_by_supplier) { create(:simple_product, supplier: producer) }

      it "can search for a product" do
        visit admin_products_v3_index_url

        search_by_producer "Producer 1"

        # expect(page).to have_content "1 product found for your search criteria."
        expect(page).to have_select "producer_id", selected: "Producer 1"
        expect_products_count_to_be 1
      end
    end

    context "product has category" do
      # create a product with a category that can be searched
      let!(:product_by_category) {
        create(:simple_product, primary_taxon: create(:taxon, name: "Category 1"))
      }

      it "can search for a product" do
        visit admin_products_v3_index_url

        search_by_category "Category 1"

        # expect(page).to have_content "1 product found for your search criteria."
        expect(page).to have_select "category_id", selected: "Category 1"
        expect_products_count_to_be 1
        expect(page).to have_field "Name", with: product_by_category.name
      end
    end
  end

  describe "updating" do
    let!(:variant_a1) { create(:variant, product: product_a, display_name: "Medium box") }
    let!(:product_a) { create(:simple_product, name: "Apples", sku: "APL-01") }

    before do
      visit admin_products_v3_index_url
    end

    it "can update product and variant fields" do
      within row_containing_name("Apples") do
        fill_in "Name", with: "Pommes"
        fill_in "SKU", with: "POM-01"
      end
      within row_containing_name("Medium box") do
        fill_in "Name", with: "Large box"
      end

      expect {
        click_button "Save changes"
        product_a.reload
        variant_a1.reload
      }.to(
        change { product_a.name }.to("Pommes")
        .and change{ product_a.sku }.to("POM-01")
        .and change{ variant_a1.display_name }.to("Large box")
      )

      within row_containing_name("Pommes") do
        expect(page).to have_field "Name", with: "Pommes"
        expect(page).to have_field "SKU", with: "POM-01"
      end
      within row_containing_name("Large box") do
        expect(page).to have_field "Name", with: "Large box"
      end

      pending
      expect(page).to have_content "Changes saved"
    end
  end

  def expect_page_to_be(page_number)
    expect(page).to have_selector ".pagination span.page.current", text: page_number.to_s
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
    # TODO: use a helper to more reliably select the tom-select component
    select producer, from: "producer_id"
    click_button "Search"
  end

  def search_by_category(category)
    select category, from: "category_id"
    click_button "Search"
  end

  # Selector for table row that has an input with this value.
  # Because there are no visible labels, the user has to assume which product it is, based on the
  # visible name.
  def row_containing_name(value)
    "tr:has(input[aria-label=Name][value='#{value}'])"
  end
end
