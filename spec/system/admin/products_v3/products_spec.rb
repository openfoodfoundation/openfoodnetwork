# frozen_string_literal: true

require "system_helper"

describe 'As an admin, I can see the new product page', feature: :admin_style_v3 do
  include WebHelper
  include AuthenticationHelper
  include FileHelper

  before do
    login_as_admin
  end

  it "can see the new product page" do
    visit admin_products_url
    expect(page).to have_content "Bulk Edit Products"
  end

  describe "sorting" do
    let!(:product_b) { create(:simple_product, name: "Bananas") }
    let!(:product_a) { create(:simple_product, name: "Apples") }

    before do
      visit admin_products_url
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
    it "has a pagination, has 15 products per page by default and can change the page" do
      create_products 16
      visit admin_products_url

      expect(page).to have_selector ".pagination"
      expect_products_count_to_be 15
      within ".pagination" do
        click_link "2"
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

      it "can search for a product" do
        create_products 1
        visit admin_products_url

        search_for "searchable product"

        expect(page).to have_field "search_term", with: "searchable product"
        # expect(page).to have_content "1 product found for your search criteria."
        expect_products_count_to_be 1
      end

      it "reset the page when searching" do
        create_products 15
        visit admin_products_url

        within ".pagination" do
          click_link "2"
        end

        expect(page).to have_content "Showing 16 to 16"
        expect_page_to_be 2
        expect_per_page_to_be 15
        expect_products_count_to_be 1
        search_for "searchable product"
        # expect(page).to have_content "1 product found for your search criteria."
        expect_products_count_to_be 1
      end

      it "can clear filters" do
        create_products 1
        visit admin_products_url

        search_for "searchable product"
        expect(page).to have_field "search_term", with: "searchable product"
        # expect(page).to have_content "1 product found for your search criteria."
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
      let!(:producer) { create(:supplier_enterprise, name: "Producer 1") }
      let!(:product_by_supplier) { create(:simple_product, supplier: producer) }

      it "can search for a product" do
        visit admin_products_url

        search_by_producer "Producer 1"

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

        # expect(page).to have_content "1 product found for your search criteria."
        expect(page).to have_select "category_id", selected: "Category 1"
        expect_products_count_to_be 1
        expect(page).to have_field "Name", with: product_by_category.name
      end
    end
  end

  describe "Actions columns (edit)" do
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

    it "shows an actions memu with an edit link when clicking on icon for product" do
      within row_containing_name("Apples") do
        page.find(".vertical-ellipsis-menu").click
        expect(page).to have_link "Edit", href: spree.edit_admin_product_path(product_a)
      end
    end

    it "shows an actions memu with an edit link when clicking on icon for variant" do
      within row_containing_name("Medium box") do
        page.find(".vertical-ellipsis-menu").click
        expect(page).to have_link "Edit",
                                  href: spree.edit_admin_product_variant_path(product_a, variant_a1)
      end
    end
  end

  describe "updating" do
    let!(:variant_a1) {
      create(:variant, product: product_a, display_name: "Medium box", sku: "APL-01", price: 5.25,
                       on_hand: 5, on_demand: false)
    }
    let!(:product_a) { create(:simple_product, name: "Apples", sku: "APL-00") }
    before do
      visit admin_products_url
    end

    it "updates product and variant fields" do
      within row_containing_name("Apples") do
        fill_in "Name", with: "Pommes"
        fill_in "SKU", with: "POM-00"
      end
      within row_containing_name("Medium box") do
        fill_in "Name", with: "Large box"
        fill_in "SKU", with: "POM-01"
        fill_in "Price", with: "10.25"
        click_on "On Hand" # activate stock popout
        fill_in "On Hand", with: "6"
      end

      expect {
        click_button "Save changes"
        product_a.reload
        variant_a1.reload
      }.to change { product_a.name }.to("Pommes")
        .and change{ product_a.sku }.to("POM-00")
        .and change{ variant_a1.display_name }.to("Large box")
        .and change{ variant_a1.sku }.to("POM-01")
        .and change{ variant_a1.price }.to(10.25)
        .and change{ variant_a1.on_hand }.to(6)

      within row_containing_name("Pommes") do
        expect(page).to have_field "Name", with: "Pommes"
        expect(page).to have_field "SKU", with: "POM-00"
      end
      within row_containing_name("Large box") do
        expect(page).to have_field "Name", with: "Large box"
        expect(page).to have_field "SKU", with: "POM-01"
        expect(page).to have_field "Price", with: "10.25"
        expect(page).to have_css "button[aria-label='On Hand']", text: "6"
      end

      expect(page).to have_content "Changes saved"
    end

    it "switches stock to on-demand" do
      within row_containing_name("Medium box") do
        click_on "On Hand" # activate stock popout
        check "On demand"

        expect(page).to have_css "button[aria-label='On Hand']", text: "On demand"
      end

      expect {
        click_button "Save changes"
        product_a.reload
        variant_a1.reload
      }.to change{ variant_a1.on_demand }.to(true)

      within row_containing_name("Medium box") do
        expect(page).to have_css "button[aria-label='On Hand']", text: "On demand"
      end

      expect(page).to have_content "Changes saved"
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
        click_button "Discard changes"
        product_a.reload
      }.to_not change { product_a.name }

      within row_containing_name("Apples") do
        expect(page).to have_field "Name", with: "Apples" # Changed value wasn't saved
        expect(page).to have_field "SKU", with: "APL-10" # Updated value shown
      end
    end

    context "with invalid data" do
      let!(:product_b) { create(:simple_product, name: "Bananas") }

      before do
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
          product_a.reload
        }.to_not change { product_a.name }

        expect(page).to have_content("1 product was saved correctly")
        expect(page).to have_content("1 product could not be saved")
        expect(page).to have_content "Please review the errors and try again"

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
        within row_containing_name("Apples") do
          fill_in "Name", with: "Pommes"
          fill_in "SKU", with: "POM-00"
        end

        expect {
          click_button "Save changes"
          product_a.reload
          variant_a1.reload
        }.to change { product_a.name }.to("Pommes")
          .and change{ product_a.sku }.to("POM-00")

        expect(page).to have_content "Changes saved"
      end
    end
  end

  describe "Cloning Feature" do
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
          expect(page).to have_link "Clone", href: spree.clone_admin_product_path(product_a)
        end

        within row_containing_name("Medium box") do
          page.find(".vertical-ellipsis-menu").click
          expect(page).to_not have_link "Clone", href: spree.clone_admin_product_path(product_a)
        end
      end
    end

    describe "Cloning product" do
      it "shows the cloned product on page when clicked on the cloned option" do
        within "table.products" do
          # Gather input values, because page.content doesn't include them.
          input_content = page.find_all('input[type=text]').map(&:value).join

          # Products does not include the cloned product.
          expect(input_content).to_not match /COPY OF Apples/
        end

        within row_containing_name("Apples") do
          page.find(".vertical-ellipsis-menu").click
          click_link('Clone')
        end

        expect(page).to have_content "Product cloned"

        within "table.products" do
          # Gather input values, because page.content doesn't include them.
          input_content = page.find_all('input[type=text]').map(&:value).join

          # Products include the cloned product.
          expect(input_content).to match /COPY OF Apples/
        end
      end
    end
  end

  def create_products(amount)
    amount.times do |i|
      create(:simple_product, name: "product #{i}")
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
