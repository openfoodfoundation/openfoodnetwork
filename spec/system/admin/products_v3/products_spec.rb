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
  # create a product with a name that can be searched
  let!(:product_by_name) { create(:simple_product, name: "searchable product") }
  # create a product with a supplier that can be searched
  let!(:producer) { create(:supplier_enterprise, name: "Producer 1") }
  let!(:product_by_supplier) { create(:simple_product, supplier: producer) }
  # create a product with a category that can be searched
  let!(:product_by_category) {
    create(:simple_product, primary_taxon: create(:taxon, name: "Category 1"))
  }

  before do
    # activate feature toggle admin_style_v3 to use new admin interface
    Flipper.enable(:admin_style_v3)
    login_as_admin
  end

  it "can see the new product page" do
    visit "/admin/products_v3"
    expect(page).to have_content "Bulk Edit Products"
  end

  context "pagination" do
    before :each do
      visit "/admin/products_v3"
    end

    it "has a pagination, has 15 products per page by default and can change the page" do
      expect(page).to have_selector ".pagination"
      expect_products_count_to_be 15
      within ".pagination" do
        click_link "2"
      end
      expect_page_to_be 2
      expect_per_page_to_be 15
      expect_products_count_to_be 15
    end

    it "can change the number of products per page" do
      select "50", from: "per_page"
      expect_page_to_be 1
      expect_per_page_to_be 50
      expect_products_count_to_be 50
    end
  end

  context "search" do
    before :each do
      visit "/admin/products_v3"
    end

    context "search by search term" do
      it "can search for a product" do
        search_for "searchable product"

        expect(page).to have_field "search_term", with: "searchable product"
        expect_page_to_be 1
        expect_products_count_to_be 1
      end

      it "reset the page when searching" do
        within ".pagination" do
          click_link "2"
        end
        expect_page_to_be 2
        expect_per_page_to_be 15
        expect_products_count_to_be 15
        search_for "searchable product"
        expect_page_to_be 1
        expect_products_count_to_be 1
      end
    end

    context "search by producer" do
      it "has a producer select" do
        expect(page).to have_selector "select#producer_id"
      end

      it "can search for a product" do
        search_by_producer "Producer 1"

        expect(page).to have_select "producer_id", selected: "Producer 1"
        expect_page_to_be 1
        expect_products_count_to_be 1
      end
    end

    context "search by category" do
      it "can search for a product" do
        search_by_category "Category 1"

        expect(page).to have_select "category_id", selected: "Category 1"
        expect_page_to_be 1
        expect_products_count_to_be 1
        expect(page).to have_selector "table.products tbody tr td", text: product_by_category.name
      end
    end

    context "clear filters" do
      it "can clear filters" do
        search_for "searchable product"
        expect(page).to have_field "search_term", with: "searchable product"
        expect_page_to_be 1
        expect_products_count_to_be 1
        expect(page).to have_selector "table.products tbody tr td", text: product_by_name.name

        click_link "Clear search"
        expect(page).to have_field "search_term", with: ""
        expect_page_to_be 1
        expect_products_count_to_be 15
      end
    end

    context "no results" do
      it "shows a message when there are no results" do
        search_for "no results"
        expect(page).to have_content "No products found for your search criteria"
        expect(page).to have_link "Clear search"
      end
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
    select producer, from: "producer_id"
    click_button "Search"
  end

  def search_by_category(category)
    select category, from: "category_id"
    click_button "Search"
  end
end
